import { GlFormRadioGroup, GlFormRadio, GlCard, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserTypeSelector from '~/admin/users/components/user_type/user_type_selector.vue';
import { stubComponent } from 'helpers/stub_component';
import AdminRoleDropdown from 'ee_component/admin/users/components/user_type/admin_role_dropdown.vue';
import AccessSummarySection from '~/admin/users/components/user_type/access_summary_section.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';

const ADMIN_ROLE_ENABLED_FLAG = { customRoles: true, customAdminRoles: true };
const ADMIN_ROLE_DISABLED_FLAGS = [
  { customRoles: false, customAdminRoles: false },
  { customRoles: true, customAdminRoles: false },
  { customRoles: false, customAdminRoles: true },
];
const ALL_FLAG_STATES = [ADMIN_ROLE_ENABLED_FLAG, ...ADMIN_ROLE_DISABLED_FLAGS];

describe('UserTypeSelector component', () => {
  let wrapper;

  const createWrapper = ({
    userType = 'regular',
    isCurrentUser = false,
    licenseAllowsAuditorUser = true,
    adminRoleId = 1,
    customRoles = true,
    customAdminRoles = true,
  } = {}) => {
    wrapper = shallowMountExtended(UserTypeSelector, {
      propsData: { userType, isCurrentUser, licenseAllowsAuditorUser, adminRoleId },
      provide: {
        glFeatures: { customRoles, customAdminRoles },
      },
      stubs: {
        AccessSummarySection,
        GlSprintf,
        AdminRoleDropdown: stubComponent(AdminRoleDropdown, { props: ['roleId'] }),
        GlFormRadio: stubComponent(GlFormRadio, {
          template: `<div>
                       <label><slot></slot></label>
                       <div class="help"><slot name="help"></slot></div>
                     </div>`,
          props: ['value', 'disabled'],
        }),
      },
    });
  };

  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioFor = (value) => wrapper.findByTestId(`user-type-${value}`);
  const findSummaryCard = () => wrapper.findComponent(GlCard);
  const findAdminRoleDropdown = () => wrapper.findComponent(AdminRoleDropdown);
  const findSummarySectionAt = (index) => wrapper.findAllComponents(AccessSummarySection).at(index);
  const findSummaryHeaderLabel = () => wrapper.findByTestId('summary-header').find('label');
  const findSummaryHeaderHelpText = () => wrapper.findByTestId('summary-header').find('p');

  const expectRegularUserGroupSectionText = () => {
    const listItems = findSummarySectionAt(1).findAll('li');

    expect(listItems).toHaveLength(1);
    expect(listItems.at(0).text()).toBe(
      'Based on member role in groups and projects. Learn more about member roles.',
    );
  };

  const expectAuditorGroupSectionText = () => {
    const listItems = findSummarySectionAt(1).findAll('li');

    expect(listItems).toHaveLength(2);
    expect(listItems.at(0).text()).toBe('Read access to all groups and projects.');
    expect(listItems.at(1).text()).toMatchInterpolatedText(
      'May be directly added to groups and projects. Learn more about auditor role.',
    );
  };

  describe('user type radio group', () => {
    beforeEach(() => createWrapper());

    it('shows the label', () => {
      expect(wrapper.find('label').text()).toBe('User type');
    });

    it('shows the label description', () => {
      const description = wrapper.find('p');

      expect(description.classes('gl-text-subtle')).toBe(true);
      expect(description.text()).toBe(
        'Define user access to groups, projects, resources, and the Admin area.',
      );
    });

    it('shows radio group', () => {
      expect(findRadioGroup().attributes('name')).toBe('user[access_level]');
    });

    describe.each`
      userType     | text               | helpText
      ${'regular'} | ${'Regular'}       | ${'Access to their groups and projects.'}
      ${'auditor'} | ${'Auditor'}       | ${'Read-only access to all groups and projects. No access to the Admin area by default.'}
      ${'admin'}   | ${'Administrator'} | ${'Full access to all groups, projects, users, features, and the Admin area.'}
    `('for $userType radio option', ({ userType, text, helpText }) => {
      it('sets the radio value', () => {
        expect(findRadioFor(userType).props('value')).toBe(userType);
      });

      it('shows the label', () => {
        expect(findRadioFor(userType).find('label').text()).toBe(text);
      });

      it('shows the help text', () => {
        expect(findRadioFor(userType).find('.help').text()).toBe(helpText);
      });
    });
  });

  describe.each`
    userType     | helpLinkText                        | helpLinkUrl                             | expectGroupSectionTextFn
    ${'regular'} | ${'Learn more about member roles.'} | ${'/help/user/permissions'}             | ${expectRegularUserGroupSectionText}
    ${'auditor'} | ${'Learn more about auditor role.'} | ${'/help/administration/auditor_users'} | ${expectAuditorGroupSectionText}
  `(
    'access summary card for $userType user',
    ({ userType, helpLinkText, helpLinkUrl, expectGroupSectionTextFn }) => {
      describe('for all feature flag states', () => {
        describe.each(ALL_FLAG_STATES)('for feature flag state %s', (state) => {
          beforeEach(() => createWrapper({ ...state, userType }));

          it('shows card', () => {
            expect(findSummaryCard().exists()).toBe(true);
          });

          it('shows card header', () => {
            expect(findSummaryHeaderLabel().text()).toBe(
              `Access summary for ${capitalizeFirstCharacter(userType)} user`,
            );
          });

          it('shows admin section', () => {
            expect(findSummarySectionAt(0).props()).toEqual({
              icon: 'admin',
              headerText: 'Admin area',
            });
          });

          describe('group section', () => {
            it('shows section', () => {
              expect(findSummarySectionAt(1).props()).toEqual({
                icon: 'group',
                headerText: 'Groups and projects',
              });
            });

            it('shows text', () => {
              expectGroupSectionTextFn();
            });

            it('shows docs link', () => {
              const link = findSummarySectionAt(1).findComponent(GlLink);

              expect(link.text()).toBe(helpLinkText);
              expect(link.props('href')).toBe(helpLinkUrl);
            });
          });

          describe('settings section', () => {
            it('shows section', () => {
              expect(findSummarySectionAt(2).props()).toEqual({
                icon: 'settings',
                headerText: 'Groups and project settings',
              });
            });

            it('shows text', () => {
              expect(findSummarySectionAt(2).text()).toContain(
                'Requires at least Maintainer role in specific groups and projects.',
              );
            });
          });
        });
      });

      describe('when admin role feature is enabled', () => {
        beforeEach(() => createWrapper({ ...ADMIN_ROLE_ENABLED_FLAG, userType: 'regular' }));

        it('shows header help text', () => {
          expect(findSummaryHeaderHelpText().text()).toBe(
            'Review and set Admin area access with a custom admin role.',
          );
        });

        it('shows admin role dropdown in admin section', () => {
          expect(findSummarySectionAt(0).findComponent(AdminRoleDropdown).props('roleId')).toBe(1);
        });
      });

      describe('for disabled admin role feature', () => {
        describe.each(ADMIN_ROLE_DISABLED_FLAGS)('for feature flag state %s', (state) => {
          beforeEach(() => createWrapper({ ...state, userType: 'regular' }));

          it('does not show header help text', () => {
            expect(findSummaryHeaderHelpText().exists()).toBe(false);
          });

          it('does not show admin role dropdown', () => {
            expect(findAdminRoleDropdown().exists()).toBe(false);
          });

          it('shows no access text in admin section', () => {
            const listItems = findSummarySectionAt(0).findAll('li');

            expect(listItems).toHaveLength(1);
            expect(listItems.at(0).text()).toBe('No access.');
          });
        });
      });
    },
  );

  describe('access summary card for admin user', () => {
    describe.each(ALL_FLAG_STATES)('for feature flags %s', (state) => {
      beforeEach(() => createWrapper({ ...state, userType: 'admin' }));

      it('shows header', () => {
        expect(findSummaryHeaderLabel().text()).toBe('Access summary for Administrator user');
      });

      it('does not show help text', () => {
        expect(findSummaryHeaderHelpText().exists()).toBe(false);
      });

      describe.each`
        section       | index
        ${'admin'}    | ${0}
        ${'group'}    | ${1}
        ${'settings'} | ${2}
      `('for $section section', ({ index }) => {
        let sectionContents;

        beforeEach(() => {
          sectionContents = findSummarySectionAt(index).find('div');
        });

        it('shows check icon', () => {
          expect(sectionContents.findComponent(GlIcon).props()).toMatchObject({
            name: 'check',
            variant: 'success',
          });
        });

        it('shows full access text', () => {
          expect(sectionContents.text()).toBe('Full read and write access.');
        });
      });
    });
  });

  describe('when user is current user', () => {
    beforeEach(() => createWrapper({ isCurrentUser: true }));

    it.each(['regular', 'auditor', 'admin'])('disables the %s radio options', (userType) => {
      expect(findRadioFor(userType).props('disabled')).toBe(true);
    });

    it('shows the help text for admin user type', () => {
      expect(findRadioFor('admin').find('.help').text()).toBe(
        'Full access to all groups, projects, users, features, and the Admin area. You cannot remove your own administrator access.',
      );
    });
  });

  describe('when license does not allow auditor user', () => {
    it('does not show auditor radio', () => {
      createWrapper({ licenseAllowsAuditorUser: false });

      expect(findRadioFor('auditor').exists()).toBe(false);
    });
  });
});

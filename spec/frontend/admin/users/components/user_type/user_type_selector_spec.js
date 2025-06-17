import { GlFormRadioGroup, GlFormRadio, GlCard, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserTypeSelector from '~/admin/users/components/user_type/user_type_selector.vue';
import { stubComponent } from 'helpers/stub_component';
import RegularAccessSummary from '~/admin/users/components/user_type/regular_access_summary.vue';
import AdminAccessSummary from '~/admin/users/components/user_type/admin_access_summary.vue';

describe('UserTypeSelector component', () => {
  let wrapper;

  const createWrapper = ({ userType = 'regular', isCurrentUser = false, scopedSlots } = {}) => {
    wrapper = shallowMountExtended(UserTypeSelector, {
      propsData: { userType, isCurrentUser },
      scopedSlots,
      stubs: {
        GlSprintf,
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

  describe('access summary card', () => {
    it('shows access summary card', () => {
      createWrapper();

      expect(findSummaryCard().exists()).toBe(true);
    });

    it('shows description slot content', () => {
      createWrapper({ scopedSlots: { description: '<template>description slot</template>' } });

      expect(findSummaryCard().find('div').text()).toContain('description slot');
    });

    describe('when there is slot content for the access summary', () => {
      beforeEach(() =>
        createWrapper({ scopedSlots: { default: '<template>slot content</template>' } }),
      );

      it('shows slot content', () => {
        expect(findSummaryCard().text()).toContain('slot content');
      });

      it('does not show access summaries', () => {
        expect(wrapper.findComponent(RegularAccessSummary).exists()).toBe(false);
        expect(wrapper.findComponent(AdminAccessSummary).exists()).toBe(false);
      });
    });
  });

  describe.each`
    userType     | name               | findAccessSummary
    ${'regular'} | ${'Regular'}       | ${() => wrapper.findComponent(RegularAccessSummary)}
    ${'admin'}   | ${'Administrator'} | ${() => wrapper.findComponent(AdminAccessSummary)}
  `('when $userType is selected', ({ userType, name, findAccessSummary }) => {
    beforeEach(() => createWrapper({ userType }));

    it('shows header in access summary card', () => {
      expect(findSummaryCard().find('label').text()).toBe(`Access summary for ${name} user`);
    });

    it('shows the access summary', () => {
      expect(findAccessSummary().exists()).toBe(true);
    });
  });

  describe('when user is current user', () => {
    beforeEach(() => createWrapper({ isCurrentUser: true }));

    it.each(['regular', 'admin'])('disables the %s radio options', (userType) => {
      expect(findRadioFor(userType).props('disabled')).toBe(true);
    });

    it('shows the help text for admin user type', () => {
      expect(findRadioFor('admin').find('.help').text()).toBe(
        'Full access to all groups, projects, users, features, and the Admin area. You cannot remove your own administrator access.',
      );
    });
  });
});

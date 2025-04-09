import { GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserTypeSelector from '~/admin/users/components/user_type/user_type_selector.vue';
import { stubComponent } from 'helpers/stub_component';

describe('UserTypeSelector component', () => {
  let wrapper;

  const createWrapper = ({
    userType = 'regular',
    isCurrentUser = false,
    licenseAllowsAuditorUser = true,
  } = {}) => {
    wrapper = shallowMountExtended(UserTypeSelector, {
      propsData: { userType, isCurrentUser, licenseAllowsAuditorUser },
      stubs: {
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

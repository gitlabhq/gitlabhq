import { GlFormInput, GlFormSelect, GlFormGroup, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserEmailSetting from '~/profile/edit/components/user_email_setting.vue';

describe('UserEmailSetting', () => {
  let wrapper;

  const defaultProps = {
    userEmailSettings: {
      email: 'user@example.com',
      publicEmail: '',
      commitEmail: 'user@example.com',
    },
  };

  const defaultProvide = {
    emailHelpText: 'We also use email for avatar detection if no avatar is uploaded.',
    emailResendConfirmationLink: null,
    isEmailReadonly: false,
    emailChangeDisabled: false,
    managingGroupName: null,
    providerLabel: null,
    publicEmailOptions: [
      { value: '', text: 'Do not show on profile' },
      { value: 'user@example.com', text: 'user@example.com' },
    ],
    commitEmailOptions: [{ value: 'user@example.com', text: 'user@example.com' }],
  };

  const createComponent = (propsData = {}, provideData = {}) => {
    wrapper = shallowMountExtended(UserEmailSetting, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      stubs: { GlFormGroup, GlLink },
    });
  };

  describe('user interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits change event with new email value when user types in email input', () => {
      const emailInput = wrapper.findByTestId('email-group').findComponent(GlFormInput);
      emailInput.vm.$emit('input', 'new@example.com');

      expect(wrapper.emitted('change')).toMatchObject([[{ email: 'new@example.com' }]]);
    });

    it.each`
      fieldType        | testId                  | inputValue            | expectedChange
      ${'publicEmail'} | ${'public-email-group'} | ${'user@example.com'} | ${{ email: 'user@example.com', publicEmail: 'user@example.com', commitEmail: 'user@example.com' }}
      ${'commitEmail'} | ${'commit-email-group'} | ${'new@commit.com'}   | ${{ email: 'user@example.com', publicEmail: '', commitEmail: 'new@commit.com' }}
    `(
      'emits change event when user updates $fieldType',
      ({ testId, inputValue, expectedChange }) => {
        const formSelect = wrapper.findByTestId(testId).findComponent(GlFormSelect);
        formSelect.vm.$emit('input', inputValue);

        expect(wrapper.emitted('change')).toEqual([[expectedChange]]);
      },
    );
  });

  describe('conditional features', () => {
    it('shows SSO help message when managed by group', () => {
      createComponent(
        {},
        {
          emailChangeDisabled: true,
          managingGroupName: 'Test Group',
        },
      );

      expect(wrapper.text()).toContain('Test Group');
      expect(wrapper.text()).toContain('SSO');
    });
  });

  describe('email resend confirmation link', () => {
    it('shows resend link when confirmation is needed', () => {
      createComponent({}, { emailResendConfirmationLink: 'https://example.com/resend' });

      expect(wrapper.text()).toContain('Resend confirmation email');
    });

    it('hides resend link when not needed', () => {
      createComponent({}, { emailResendConfirmationLink: null });

      expect(wrapper.text()).not.toContain('Resend confirmation email');
    });
  });
});

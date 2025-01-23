import { within } from '@testing-library/dom';
import { shallowMount, mount, createWrapper } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { mockData } from 'jest/admin/signup_restrictions/mock_data';
import SignupForm from '~/pages/admin/application_settings/general/components/signup_form.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('SignUpRestrictionsApp', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const mountComponent = ({ injectedProps = {}, mountFn = shallowMount, stubs = {} } = {}) => {
    wrapper = extendedWrapper(
      mountFn(SignupForm, {
        provide: {
          ...mockData,
          ...injectedProps,
        },
        stubs,
      }),
    );
  };

  const queryByLabelText = (text) => within(wrapper.element).queryByLabelText(text);

  const findForm = () => wrapper.findByTestId('form');
  const findInputCsrf = () => findForm().find('[name="authenticity_token"]');

  const findDenyListRawRadio = () => queryByLabelText('Enter denylist manually');
  const findDenyListFileRadio = () => queryByLabelText('Upload denylist file');

  const findDenyListRawInputGroup = () => wrapper.findByTestId('domain-denylist-raw-input-group');
  const findDenyListFileInputGroup = () => wrapper.findByTestId('domain-denylist-file-input-group');

  describe('form data', () => {
    beforeEach(() => {
      mountComponent();
    });

    it.each`
      prop                                     | propValue                                       | elementSelector                                                             | formElementPassedDataType | formElementKey | expected
      ${'signupEnabled'}                       | ${mockData.signupEnabled}                       | ${'[name="application_setting[signup_enabled]"]'}                           | ${'prop'}                 | ${'value'}     | ${mockData.signupEnabled}
      ${'requireAdminApprovalAfterUserSignup'} | ${mockData.requireAdminApprovalAfterUserSignup} | ${'[name="application_setting[require_admin_approval_after_user_signup]"]'} | ${'prop'}                 | ${'value'}     | ${mockData.requireAdminApprovalAfterUserSignup}
      ${'minimumPasswordLength'}               | ${mockData.minimumPasswordLength}               | ${'[name="application_setting[minimum_password_length]"]'}                  | ${'attribute'}            | ${'value'}     | ${mockData.minimumPasswordLength}
      ${'minimumPasswordLengthMin'}            | ${mockData.minimumPasswordLengthMin}            | ${'[name="application_setting[minimum_password_length]"]'}                  | ${'attribute'}            | ${'min'}       | ${mockData.minimumPasswordLengthMin}
      ${'minimumPasswordLengthMax'}            | ${mockData.minimumPasswordLengthMax}            | ${'[name="application_setting[minimum_password_length]"]'}                  | ${'attribute'}            | ${'max'}       | ${mockData.minimumPasswordLengthMax}
      ${'domainAllowlistRaw'}                  | ${mockData.domainAllowlistRaw}                  | ${'[name="application_setting[domain_allowlist_raw]"]'}                     | ${'value'}                | ${'value'}     | ${mockData.domainAllowlistRaw}
      ${'domainDenylistEnabled'}               | ${mockData.domainDenylistEnabled}               | ${'[name="application_setting[domain_denylist_enabled]"]'}                  | ${'prop'}                 | ${'value'}     | ${mockData.domainDenylistEnabled}
      ${'denylistTypeRawSelected'}             | ${mockData.denylistTypeRawSelected}             | ${'[name="denylist_type"]'}                                                 | ${'attribute'}            | ${'checked'}   | ${'raw'}
      ${'domainDenylistRaw'}                   | ${mockData.domainDenylistRaw}                   | ${'[name="application_setting[domain_denylist_raw]"]'}                      | ${'value'}                | ${'value'}     | ${mockData.domainDenylistRaw}
      ${'emailRestrictionsEnabled'}            | ${mockData.emailRestrictionsEnabled}            | ${'[name="application_setting[email_restrictions_enabled]"]'}               | ${'prop'}                 | ${'value'}     | ${mockData.emailRestrictionsEnabled}
      ${'emailRestrictions'}                   | ${mockData.emailRestrictions}                   | ${'[name="application_setting[email_restrictions]"]'}                       | ${'value'}                | ${'value'}     | ${mockData.emailRestrictions}
      ${'afterSignUpText'}                     | ${mockData.afterSignUpText}                     | ${'[name="application_setting[after_sign_up_text]"]'}                       | ${'value'}                | ${'value'}     | ${mockData.afterSignUpText}
    `(
      'form element $elementSelector gets $expected value for $formElementKey $formElementPassedDataType when prop $prop is set to $propValue',
      ({ elementSelector, expected, formElementKey, formElementPassedDataType }) => {
        const formElement = wrapper.find(elementSelector);

        switch (formElementPassedDataType) {
          case 'attribute':
            expect(formElement.attributes(formElementKey)).toBe(expected);
            break;
          case 'prop':
            expect(formElement.props(formElementKey)).toBe(expected);
            break;
          case 'value':
            expect(formElement.element.value).toBe(expected);
            break;
          default:
            expect(formElement.props(formElementKey)).toBe(expected);
            break;
        }
      },
    );
    it('gets passed the path for action attribute', () => {
      expect(findForm().attributes('action')).toBe(mockData.settingsPath);
    });

    it('gets passed the csrf token as a hidden input value', () => {
      expect(findInputCsrf().attributes('type')).toBe('hidden');

      expect(findInputCsrf().attributes('value')).toBe('mock-csrf-token');
    });
  });

  describe('domain deny list', () => {
    describe('when it is set to raw from props', () => {
      beforeEach(() => {
        mountComponent({ mountFn: mount });
      });

      it('has raw list selected', () => {
        expect(findDenyListRawRadio().checked).toBe(true);
      });

      it('has file not selected', () => {
        expect(findDenyListFileRadio().checked).toBe(false);
      });

      it('raw list input is displayed', () => {
        expect(findDenyListRawInputGroup().exists()).toBe(true);
      });

      it('file input is not displayed', () => {
        expect(findDenyListFileInputGroup().exists()).toBe(false);
      });

      describe('when user clicks on file radio', () => {
        beforeEach(() => {
          createWrapper(findDenyListFileRadio()).setChecked(true);
        });

        it('has raw list not selected', () => {
          expect(findDenyListRawRadio().checked).toBe(false);
        });

        it('has file selected', () => {
          expect(findDenyListFileRadio().checked).toBe(true);
        });

        it('raw list input is not displayed', () => {
          expect(findDenyListRawInputGroup().exists()).toBe(false);
        });

        it('file input is displayed', () => {
          expect(findDenyListFileInputGroup().exists()).toBe(true);
        });
      });
    });

    describe('when it is set to file from injected props', () => {
      beforeEach(() => {
        mountComponent({ mountFn: mount, injectedProps: { denylistTypeRawSelected: false } });
      });

      it('has raw list not selected', () => {
        expect(findDenyListRawRadio().checked).toBe(false);
      });

      it('has file selected', () => {
        expect(findDenyListFileRadio().checked).toBe(true);
      });

      it('raw list input is not displayed', () => {
        expect(findDenyListRawInputGroup().exists()).toBe(false);
      });

      it('file input is displayed', () => {
        expect(findDenyListFileInputGroup().exists()).toBe(true);
      });

      describe('when user clicks on raw list radio', () => {
        beforeEach(() => {
          createWrapper(findDenyListRawRadio()).setChecked(true);
        });

        it('has raw list selected', () => {
          expect(findDenyListRawRadio().checked).toBe(true);
        });

        it('has file not selected', () => {
          expect(findDenyListFileRadio().checked).toBe(false);
        });

        it('raw list input is displayed', () => {
          expect(findDenyListRawInputGroup().exists()).toBe(true);
        });

        it('file input is not displayed', () => {
          expect(findDenyListFileInputGroup().exists()).toBe(false);
        });
      });
    });
  });
});

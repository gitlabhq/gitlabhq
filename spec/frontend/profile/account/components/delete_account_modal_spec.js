import { GlModal, GlSprintf } from '@gitlab/ui';
import DeleteAccountModal from '~/profile/account/components/delete_account_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('DeleteAccountModal component', () => {
  let wrapper;

  const createWrapper = ({
    confirmWithPassword = true,
    delayUserAccountSelfDeletion = false,
  } = {}) => {
    wrapper = shallowMountExtended(DeleteAccountModal, {
      propsData: {
        actionUrl: 'http://delete/user',
        username: 'hasnoname',
        confirmWithPassword,
        delayUserAccountSelfDeletion,
      },
      stubs: { GlSprintf },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.find('form');
  const findPasswordInput = () => wrapper.findByTestId('password-confirmation-field');
  const findUsernameInput = () => wrapper.findByTestId('username-confirmation-field');

  it.each`
    delayUserAccountSelfDeletion | expectedMessage
    ${false}                     | ${'You are about to permanently delete your account, and all of the issues, merge requests, and groups linked to your account. Once you confirm Delete account, your account cannot be recovered.'}
    ${true}                      | ${'You are about to permanently delete your account, and all of the issues, merge requests, and groups linked to your account. Once you confirm Delete account, your account cannot be recovered. It might take up to seven days before you can create a new account with the same username or email.'}
  `(
    'shows delete message in modal body when delayUserAccountSelfDeletion is $delayUserAccountSelfDeletion',
    ({ delayUserAccountSelfDeletion, expectedMessage }) => {
      createWrapper({ delayUserAccountSelfDeletion });

      expect(findModal().find('p').text()).toBe(expectedMessage);
    },
  );

  describe.each`
    type          | confirmWithPassword | findExpectedField    | findOtherField       | invalidFieldValue  | validFieldValue
    ${'password'} | ${true}             | ${findPasswordInput} | ${findUsernameInput} | ${''}              | ${'anything'}
    ${'username'} | ${false}            | ${findUsernameInput} | ${findPasswordInput} | ${'this is wrong'} | ${'hasnoname'}
  `(
    'with $type confirmation',
    ({
      type,
      confirmWithPassword,
      findExpectedField,
      findOtherField,
      invalidFieldValue,
      validFieldValue,
    }) => {
      let submitSpy;

      beforeEach(() => {
        createWrapper({ confirmWithPassword });
        submitSpy = jest.spyOn(findForm().element, 'submit');
      });

      it('shows expected input field', () => {
        expect(findExpectedField().exists()).toBe(true);
      });

      it('does not show other input field', () => {
        expect(findOtherField().exists()).toBe(false);
      });

      it('shows confirmation message in form', () => {
        expect(findForm().find('p').text()).toBe(`Type your ${type} to confirm:`);
      });

      describe('when the field has an invalid value', () => {
        beforeEach(() => findExpectedField().setValue(invalidFieldValue));

        it('disables submit button', () => {
          expect(findModal().props('actionPrimary').attributes.disabled).toBe(true);
        });

        it('does not submit form when delete button is clicked', () => {
          findModal().vm.$emit('primary');

          expect(submitSpy).not.toHaveBeenCalled();
        });
      });

      describe('when the field has a valid value', () => {
        beforeEach(() => findExpectedField().setValue(validFieldValue));

        it('enables submit button', () => {
          expect(findModal().props('actionPrimary').attributes.disabled).toBe(false);
        });

        it('submits form when delete button is clicked', () => {
          findModal().vm.$emit('primary');

          expect(submitSpy).toHaveBeenCalledTimes(1);
        });
      });
    },
  );
});

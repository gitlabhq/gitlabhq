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
    delayUserAccountSelfDeletion | message
    ${false}                     | ${'You are about to permanently delete <strong>your account</strong>, and all of the issues, merge requests, and groups linked to your account. Once you confirm <strong>Delete account</strong>, your account cannot be recovered.'}
    ${true}                      | ${'You are about to permanently delete <strong>your account</strong>, and all of the issues, merge requests, and groups linked to your account. Once you confirm <strong>Delete account</strong>, your account cannot be recovered. It might take up to seven days before you can create a new account with the same username or email.'}
  `(
    'shows delete message in modal body when delayUserAccountSelfDeletion is $delayUserAccountSelfDeletion',
    ({ delayUserAccountSelfDeletion, message }) => {
      createWrapper({ delayUserAccountSelfDeletion });

      const content = findModal().find('p').html();
      expect(content).toContain(message);
    },
  );

  describe.each`
    message                                          | confirmWithPassword | findExpectedField    | findOtherField       | invalidFieldValue  | validFieldValue
    ${'Type your <code>password</code> to confirm:'} | ${true}             | ${findPasswordInput} | ${findUsernameInput} | ${''}              | ${'anything'}
    ${'Type your <code>username</code> to confirm:'} | ${false}            | ${findUsernameInput} | ${findPasswordInput} | ${'this is wrong'} | ${'hasnoname'}
  `(
    'with $type confirmation',
    ({
      message,
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
        const content = findForm().find('p').html();
        expect(content).toContain(message);
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

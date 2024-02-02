import { GlModal } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  I18N_PASSWORD_PROMPT_CANCEL_BUTTON,
  I18N_PASSWORD_PROMPT_CONFIRM_BUTTON,
} from '~/profile/password_prompt/constants';
import PasswordPromptModal from '~/profile/password_prompt/password_prompt_modal.vue';

const createComponent = ({ props }) => {
  return shallowMountExtended(PasswordPromptModal, {
    propsData: {
      ...props,
    },
  });
};

describe('Password prompt modal', () => {
  let wrapper;

  const mockPassword = 'not+fake+shady+password';
  const mockEvent = { preventDefault: jest.fn() };
  const handleConfirmPasswordSpy = jest.fn();

  const findField = () => wrapper.findByTestId('password-prompt-field');
  const findModal = () => wrapper.findComponent(GlModal);
  const findConfirmBtn = () => findModal().props('actionPrimary');
  const findConfirmBtnDisabledState = () => findModal().props('actionPrimary').attributes.disabled;

  const findCancelBtn = () => findModal().props('actionCancel');

  const submitModal = () => findModal().vm.$emit('primary', mockEvent);
  const setPassword = (newPw) => findField().vm.$emit('input', newPw);

  beforeEach(() => {
    wrapper = createComponent({
      props: {
        handleConfirmPassword: handleConfirmPasswordSpy,
      },
    });
  });

  it('renders the password field', () => {
    expect(findField().exists()).toBe(true);
  });

  it('renders the confirm button', () => {
    expect(findConfirmBtn().text).toEqual(I18N_PASSWORD_PROMPT_CONFIRM_BUTTON);
  });

  it('renders the cancel button', () => {
    expect(findCancelBtn().text).toEqual(I18N_PASSWORD_PROMPT_CANCEL_BUTTON);
  });

  describe('confirm button', () => {
    describe('with a valid password', () => {
      it('calls the `handleConfirmPassword` method when clicked', async () => {
        setPassword(mockPassword);
        submitModal();

        await nextTick();

        expect(handleConfirmPasswordSpy).toHaveBeenCalledTimes(1);
        expect(handleConfirmPasswordSpy).toHaveBeenCalledWith(mockPassword);
      });

      it('enables the confirm button', async () => {
        setPassword(mockPassword);

        expect(findConfirmBtnDisabledState()).toBe(true);

        await nextTick();

        expect(findConfirmBtnDisabledState()).toBe(false);
      });
    });

    it('without a valid password is disabled', async () => {
      setPassword('');

      expect(findConfirmBtnDisabledState()).toBe(true);

      await nextTick();

      expect(findConfirmBtnDisabledState()).toBe(true);
    });
  });
});

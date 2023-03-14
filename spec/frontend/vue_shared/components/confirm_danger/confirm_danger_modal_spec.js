import { GlModal, GlSprintf } from '@gitlab/ui';
import {
  CONFIRM_DANGER_WARNING,
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_ID,
  CONFIRM_DANGER_MODAL_CANCEL,
} from '~/vue_shared/components/confirm_danger/constants';
import ConfirmDangerModal from '~/vue_shared/components/confirm_danger/confirm_danger_modal.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

describe('Confirm Danger Modal', () => {
  const confirmDangerMessage = 'This is a dangerous activity';
  const confirmButtonText = 'Confirm button text';
  const cancelButtonText = 'Cancel button text';
  const phrase = 'You must construct additional pylons';
  const modalId = CONFIRM_DANGER_MODAL_ID;

  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findConfirmationPhrase = () => wrapper.findByTestId('confirm-danger-phrase');
  const findConfirmationInput = () => wrapper.findByTestId('confirm-danger-input');
  const findDefaultWarning = () => wrapper.findByTestId('confirm-danger-warning');
  const findAdditionalMessage = () => wrapper.findByTestId('confirm-danger-message');
  const findPrimaryAction = () => findModal().props('actionPrimary');
  const findCancelAction = () => findModal().props('actionCancel');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[attr];

  const createComponent = ({ provide = {} } = {}) =>
    shallowMountExtended(ConfirmDangerModal, {
      propsData: {
        modalId,
        phrase,
      },
      provide,
      stubs: { GlSprintf },
    });

  beforeEach(() => {
    wrapper = createComponent({
      provide: { confirmDangerMessage, confirmButtonText, cancelButtonText },
    });
  });

  it('renders the default warning message', () => {
    expect(findDefaultWarning().text()).toBe(CONFIRM_DANGER_WARNING);
  });

  it('renders any additional messages', () => {
    expect(findAdditionalMessage().text()).toBe(confirmDangerMessage);
  });

  it('renders the confirm button', () => {
    expect(findPrimaryAction().text).toBe(confirmButtonText);
    expect(findPrimaryActionAttributes('variant')).toBe('danger');
  });

  it('renders the cancel button', () => {
    expect(findCancelAction().text).toBe(cancelButtonText);
  });

  it('renders the correct confirmation phrase', () => {
    expect(findConfirmationPhrase().text()).toBe(
      `Please type ${phrase} to proceed or close this modal to cancel.`,
    );
  });

  describe('without injected data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('does not render any additional messages', () => {
      expect(findAdditionalMessage().exists()).toBe(false);
    });

    it('renders the default confirm button', () => {
      expect(findPrimaryAction().text).toBe(CONFIRM_DANGER_MODAL_BUTTON);
    });

    it('renders the default cancel button', () => {
      expect(findCancelAction().text).toBe(CONFIRM_DANGER_MODAL_CANCEL);
    });
  });

  describe('with a valid confirmation phrase', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('enables the confirm button', async () => {
      expect(findPrimaryActionAttributes('disabled')).toBe(true);

      await findConfirmationInput().vm.$emit('input', phrase);

      expect(findPrimaryActionAttributes('disabled')).toBe(false);
    });

    it('emits a `confirm` event when the button is clicked', async () => {
      expect(wrapper.emitted('confirm')).toBeUndefined();

      await findConfirmationInput().vm.$emit('input', phrase);
      await findModal().vm.$emit('primary');

      expect(wrapper.emitted('confirm')).not.toBeUndefined();
    });
  });
});

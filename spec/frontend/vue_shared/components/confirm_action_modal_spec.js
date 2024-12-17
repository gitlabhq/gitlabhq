import { mount } from '@vue/test-utils';
import { GlModal, GlAlert } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import ConfirmActionModal from '~/vue_shared/components/confirm_action_modal.vue';
import { stubComponent, RENDER_ALL_SLOTS_TEMPLATE } from 'helpers/stub_component';

describe('Confirm action modal', () => {
  let wrapper;
  // Need to wait for promises, or else the action function resolves too quickly and we can't test the loading state.
  const defaultActionFn = jest.fn().mockImplementation(waitForPromises);
  const preventDefault = jest.fn();

  const createComponent = ({
    title,
    actionText = 'Delete',
    actionFn = defaultActionFn,
    variant,
    cancelText,
  } = {}) => {
    wrapper = mount(ConfirmActionModal, {
      propsData: { modalId: 'modal', title, actionText, actionFn, variant, cancelText },
      slots: { default: 'Do you really want to delete?' },
      stubs: {
        GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const clickOkButton = () => {
    findModal().vm.$emit('primary', { preventDefault });
  };

  describe('modal', () => {
    beforeEach(() => createComponent({ title: 'Really delete?' }));

    it('shows modal', () => {
      expect(findModal().props()).toMatchObject({ visible: true, size: 'sm' });
    });

    it('shows title', () => {
      expect(findModal().props('title')).toBe('Really delete?');
    });

    it('shows description', () => {
      expect(findModal().text()).toContain('Do you really want to delete?');
    });

    it.each`
      action                                 | trigger
      ${'cancel button is clicked'}          | ${'cancel'}
      ${'escape key is pressed'}             | ${'esc'}
      ${'backdrop was clicked'}              | ${'backdrop'}
      ${'X icon in the header is clicked'}   | ${'headerclose'}
      ${'closed by calling hide() function'} | ${null}
    `('closes the modal when $action', ({ trigger }) => {
      findModal().vm.$emit('hide', { trigger, preventDefault });
      // Check that the modal was not prevented from closing.
      expect(preventDefault).not.toHaveBeenCalled();
    });

    describe('OK button', () => {
      beforeEach(() => createComponent({ actionText: 'Remove', variant: 'danger' }));

      it('show expected text', () => {
        expect(findModal().props('actionPrimary').text).toBe('Remove');
      });

      it('shows expected variant', () => {
        expect(findModal().props('actionPrimary').attributes.variant).toBe('danger');
      });
    });

    describe('Cancel button', () => {
      beforeEach(() => createComponent({ cancelText: 'Nevermind' }));

      it('shows expected text', () => {
        expect(findModal().props('actionCancel').text).toBe('Nevermind');
      });
    });
  });

  describe('when OK button is clicked', () => {
    beforeEach(() => {
      createComponent();
      clickOkButton();
    });

    it('prevents the modal from closing', () => {
      expect(preventDefault).toHaveBeenCalledTimes(1);
    });

    it('calls the action function', () => {
      expect(defaultActionFn).toHaveBeenCalledTimes(1);
    });

    it('shows the action button as loading', () => {
      expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
    });

    it('shows the cancel button as disabled', () => {
      expect(findModal().props('actionCancel').attributes.disabled).toBe(true);
    });

    it('prevents the modal from closing from user action', () => {
      findModal().vm.$emit('hide', { trigger: 'backdrop', preventDefault });
      // Check that the close was stopped 2 times, once for the OK click and once for the user action.
      expect(preventDefault).toHaveBeenCalledTimes(2);
    });

    describe('when action is complete', () => {
      beforeEach(() => {
        // The component calls hide() on the modal, which triggers the hide event.
        findModal().vm.$emit('hide', { trigger: null, preventDefault });
      });

      it('keeps the action button as loading', () => {
        expect(findModal().props('actionPrimary').attributes.loading).toBe(true);
      });

      it('keeps the cancel button as disabled', () => {
        expect(findModal().props('actionCancel').attributes.disabled).toBe(true);
      });

      it('closes the modal', () => {
        // Check that the close was stopped only once for the OK click, but not for the hide.
        expect(preventDefault).toHaveBeenCalledTimes(1);
      });

      it('emits the close event', () => {
        findModal().vm.$emit('hidden');

        expect(wrapper.emitted('close')).toHaveLength(1);
      });
    });
  });

  describe('when the action fails', () => {
    beforeEach(() => {
      const error = new Error('delete failed');
      const actionFn = jest.fn().mockImplementation(async () => {
        await waitForPromises();
        return Promise.reject(error);
      });

      createComponent({ actionFn });
      clickOkButton();
      return waitForPromises();
    });

    it('shows an error message', () => {
      expect(findAlert().props()).toMatchObject({ variant: 'danger', dismissible: false });
      expect(findAlert().text()).toBe('delete failed');
    });

    describe('when the OK button is clicked again', () => {
      beforeEach(() => {
        clickOkButton();
      });

      it('clears the error message', () => {
        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});

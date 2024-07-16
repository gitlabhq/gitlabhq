import { GlModal, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import {
  CONFIRM_DANGER_MODAL_BUTTON,
  CONFIRM_DANGER_MODAL_ID,
  CONFIRM_DANGER_MODAL_CANCEL,
  CONFIRM_DANGER_MODAL_TITLE,
  CONFIRM_DANGER_WARNING,
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
  const findConfirmationInput = () => wrapper.findByTestId('confirm-danger-field');
  const findAdditionalMessage = () => wrapper.findByTestId('confirm-danger-message');
  const findPrimaryAction = () => findModal().props('actionPrimary');
  const findCancelAction = () => findModal().props('actionCancel');
  const findPrimaryActionAttributes = (attr) => findPrimaryAction().attributes[attr];

  const createComponent = ({ props = {}, provide = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(ConfirmDangerModal, {
      propsData: {
        modalId,
        phrase,
        visible: false,
        ...props,
      },
      provide,
      slots,
      stubs: { GlSprintf },
    });
  };

  describe('with injected data', () => {
    beforeEach(() => {
      createComponent({
        provide: { confirmDangerMessage, confirmButtonText, cancelButtonText },
      });
    });

    it('renders the correct confirmation phrase', () => {
      expect(findConfirmationPhrase().text()).toBe(`Enter the following to confirm:`);
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
  });

  describe('without injected data', () => {
    beforeEach(() => {
      createComponent();
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
      createComponent();
    });

    it('enables the confirm button', async () => {
      expect(findPrimaryActionAttributes('disabled')).toBe(true);

      await findConfirmationInput().vm.$emit('input', phrase);

      expect(findPrimaryActionAttributes('disabled')).toBe(false);
    });

    it('emits a `confirm` event with the $event when the button is clicked', async () => {
      const MOCK_EVENT = new Event('primaryEvent');
      expect(wrapper.emitted('confirm')).toBeUndefined();

      await findConfirmationInput().vm.$emit('input', phrase);
      await findModal().vm.$emit('primary', MOCK_EVENT);

      expect(wrapper.emitted('confirm')).toEqual([[MOCK_EVENT]]);
    });
  });

  describe('v-model', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emit `change` event', () => {
      findModal().vm.$emit('change', true);

      expect(wrapper.emitted('change')).toEqual([[true]]);
    });

    it('sets `visible` prop', () => {
      expect(findModal().props('visible')).toBe(false);
    });
  });

  describe('when confirm loading is true', () => {
    beforeEach(() => {
      createComponent({ props: { confirmLoading: true } });
    });

    it('when confirmLoading switches from true to false, emits `change event`', async () => {
      // setProps is justified here because we are testing the component's
      // reactive behavior which constitutes an exception
      // See https://docs.gitlab.com/ee/development/fe_guide/style/vue.html#setting-component-state
      wrapper.setProps({ confirmLoading: false });

      await nextTick();

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });

  describe('modal title', () => {
    describe('with no prop', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders default title', () => {
        expect(findModal().props('title')).toBe(CONFIRM_DANGER_MODAL_TITLE);
      });
    });

    describe('with custom prop', () => {
      const MOCK_TITLE = 'New Title';

      beforeEach(() => {
        createComponent({ props: { modalTitle: MOCK_TITLE } });
      });

      it('renders custom title', () => {
        expect(findModal().props('title')).toBe(MOCK_TITLE);
      });
    });
  });

  describe('modal body slot', () => {
    describe('when not using slot', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders default body', () => {
        expect(wrapper.findByTestId('confirm-danger-warning').text()).toBe(CONFIRM_DANGER_WARNING);
      });
    });

    describe('when using slot', () => {
      const MOCK_BODY = 'New Body Text';

      beforeEach(() => {
        createComponent({
          slots: {
            'modal-body': `<span>${MOCK_BODY}</span>`,
          },
        });
      });

      it('renders custom body', () => {
        expect(wrapper.findByTestId('confirm-danger-warning').exists()).toBe(false);
        expect(wrapper.text()).toContain(MOCK_BODY);
      });
    });
  });

  describe('modal footer slot', () => {
    const MOCK_FOOTER = 'New Footer';

    describe('when not using slot', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not render custom footer', () => {
        expect(wrapper.text()).not.toContain(MOCK_FOOTER);
      });
    });

    describe('when using slot', () => {
      beforeEach(() => {
        createComponent({
          slots: {
            'modal-footer': `<span>${MOCK_FOOTER}</span>`,
          },
        });
      });

      it('renders custom footer', () => {
        expect(wrapper.text()).toContain(MOCK_FOOTER);
      });
    });
  });
});

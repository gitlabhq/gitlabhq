import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ConfirmModal from '~/lib/utils/confirm_via_gl_modal/confirm_modal.vue';

describe('Confirm Modal', () => {
  let wrapper;
  let modal;
  const SECONDARY_TEXT = 'secondaryText';
  const SECONDARY_VARIANT = 'danger';

  const createComponent = ({
    primaryText,
    primaryVariant,
    secondaryText,
    secondaryVariant,
    title,
    size,
    hideCancel = false,
  } = {}) => {
    wrapper = mount(ConfirmModal, {
      propsData: {
        primaryText,
        primaryVariant,
        secondaryText,
        secondaryVariant,
        hideCancel,
        title,
        size,
      },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);

  describe('Modal events', () => {
    beforeEach(() => {
      createComponent();
      modal = findGlModal();
    });

    it('should emit `confirmed` event on `primary` modal event', () => {
      findGlModal().vm.$emit('primary');
      expect(wrapper.emitted('confirmed')).toHaveLength(1);
    });

    it('should emit closed` event on `hidden` modal event', () => {
      modal.vm.$emit('hidden');
      expect(wrapper.emitted('closed')).toHaveLength(1);
    });
  });

  describe('Custom properties', () => {
    it('should pass correct custom primary text & button variant to the modal when provided', () => {
      const primaryText = "Let's do it!";
      const primaryVariant = 'danger';

      createComponent({ primaryText, primaryVariant });
      const customProps = findGlModal().props('actionPrimary');
      expect(customProps.text).toBe(primaryText);
      expect(customProps.attributes.variant).toBe(primaryVariant);
    });

    it('should pass default primary text & button variant to the modal if no custom values provided', () => {
      createComponent();
      const customProps = findGlModal().props('actionPrimary');
      expect(customProps.text).toBe('OK');
      expect(customProps.attributes.variant).toBe('confirm');
    });

    it('should hide the cancel button if `hideCancel` is set', () => {
      createComponent({ hideCancel: true });
      const props = findGlModal().props();

      expect(props.actionCancel).toBeNull();
    });

    it('should not show secondary Button when secondary Text is not set', () => {
      createComponent();
      const props = findGlModal().props();
      expect(props.actionSecondary).toBeNull();
    });

    it('should show secondary Button when secondaryText is set', () => {
      createComponent({ secondaryText: SECONDARY_TEXT, secondaryVariant: SECONDARY_VARIANT });
      const actionSecondary = findGlModal().props('actionSecondary');
      expect(actionSecondary.text).toEqual(SECONDARY_TEXT);
      expect(actionSecondary.attributes.variant).toEqual(SECONDARY_VARIANT);
    });

    it('should set the modal title when the `title` prop is set', () => {
      const title = 'Modal title';
      createComponent({ title });

      expect(findGlModal().props().title).toBe(title);
    });

    it('should set modal size to `sm` by default', () => {
      createComponent();

      expect(findGlModal().props('size')).toBe('sm');
    });

    it('should set modal size when `size` prop is set', () => {
      createComponent({ size: 'md' });

      expect(findGlModal().props('size')).toBe('md');
    });
  });
});

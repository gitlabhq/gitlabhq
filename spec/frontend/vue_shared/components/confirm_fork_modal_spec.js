import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ConfirmForkModal, { i18n } from '~/vue_shared/components/confirm_fork_modal.vue';

describe('vue_shared/components/confirm_fork_modal', () => {
  let wrapper = null;

  const forkPath = '/fake/fork/path';
  const modalId = 'confirm-fork-modal';
  const defaultProps = { modalId, forkPath };

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalProp = (prop) => findModal().props(prop);
  const findModalActionProps = () => findModalProp('actionPrimary');

  const createComponent = (props = {}) =>
    shallowMountExtended(ConfirmForkModal, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });

  describe('visible = false', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('sets the visible prop to `false`', () => {
      expect(findModalProp('visible')).toBe(false);
    });

    it('sets the modal title', () => {
      const title = findModalProp('title');
      expect(title).toBe(i18n.title);
    });

    it('sets the modal id', () => {
      const fakeModalId = findModalProp('modalId');
      expect(fakeModalId).toBe(modalId);
    });

    it('has the fork path button', () => {
      const modalProps = findModalActionProps();
      expect(modalProps.text).toBe(i18n.btnText);
      expect(modalProps.attributes.variant).toBe('confirm');
    });

    it('sets the correct fork path', () => {
      const modalProps = findModalActionProps();
      expect(modalProps.attributes.href).toBe(forkPath);
    });

    it('has the fork message', () => {
      expect(findModal().text()).toContain(i18n.message);
    });
  });

  describe('visible = true', () => {
    beforeEach(() => {
      wrapper = createComponent({ visible: true });
    });

    it('sets the visible prop to `true`', () => {
      expect(findModalProp('visible')).toBe(true);
    });

    it('emits the `change` event if the modal is hidden', () => {
      expect(wrapper.emitted('change')).toBeUndefined();

      findModal().vm.$emit('change', false);

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });
  });
});

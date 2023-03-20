import { GlSprintf, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeletePackageModal from '~/packages_and_registries/shared/components/delete_package_modal.vue';

describe('DeletePackageModal', () => {
  let wrapper;

  const defaultItemToBeDeleted = {
    name: 'package 01',
  };

  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = ({ itemToBeDeleted = defaultItemToBeDeleted } = {}) => {
    wrapper = shallowMountExtended(DeletePackageModal, {
      propsData: {
        itemToBeDeleted,
      },
    });
  };

  describe('when itemToBeDeleted prop is defined', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('displays modal', () => {
      expect(findModal().props('visible')).toBe(true);
    });

    it('passes title prop', () => {
      expect(findModal().props('title')).toBe(wrapper.vm.$options.i18n.modalTitle);
    });

    it('passes actionPrimary prop', () => {
      expect(findModal().props('actionPrimary')).toStrictEqual({
        text: wrapper.vm.$options.i18n.modalAction,
        attributes: {
          variant: 'danger',
        },
      });
    });

    it('displays description', () => {
      const descriptionEl = findModal().findComponent(GlSprintf);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.attributes('message')).toBe(wrapper.vm.$options.i18n.modalDescription);
    });

    it('emits ok when modal is validate', () => {
      expect(wrapper.emitted().ok).toBeUndefined();

      findModal().vm.$emit('ok');

      expect(wrapper.emitted().ok).toHaveLength(1);
    });

    it('emits cancel when modal close', () => {
      expect(wrapper.emitted().cancel).toBeUndefined();

      findModal().vm.$emit('change', false);

      expect(wrapper.emitted().cancel).toHaveLength(1);
    });
  });

  describe('when itemToBeDeleted prop is null', () => {
    beforeEach(() => {
      mountComponent({ itemToBeDeleted: null });
    });

    it("doesn't display modal", () => {
      expect(findModal().props('visible')).toBe(false);
    });
  });
});

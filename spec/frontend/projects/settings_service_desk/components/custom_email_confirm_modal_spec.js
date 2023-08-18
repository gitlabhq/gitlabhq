import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CustomEmailConfirmModal from '~/projects/settings_service_desk/components/custom_email_confirm_modal.vue';

describe('CustomEmailConfirmModal', () => {
  let wrapper;

  const defaultProps = { visible: false, customEmail: 'user@example.com' };

  const findModal = () => wrapper.findComponent(GlModal);

  const createWrapper = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(CustomEmailConfirmModal, { propsData: { ...defaultProps, ...props } }),
    );
  };

  it('does not display modal', () => {
    createWrapper();

    expect(findModal().props('visible')).toBe(false);
  });

  describe('when visible', () => {
    beforeEach(() => {
      createWrapper({ visible: true });
    });

    it('displays the modal', () => {
      expect(findModal().props('visible')).toBe(true);
    });

    it('emits remove event on primary button click', () => {
      findModal().vm.$emit('primary');

      expect(wrapper.emitted('remove')).toEqual([[]]);
    });

    it('emits cancel event on cancel button click', () => {
      findModal().vm.$emit('canceled');

      expect(wrapper.emitted('cancel')).toEqual([[]]);
    });

    it('emits cancel event on close button click', () => {
      findModal().vm.$emit('hidden');

      expect(wrapper.emitted('cancel')).toEqual([[]]);
    });
  });
});

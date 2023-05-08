import { shallowMount, createWrapper } from '@vue/test-utils';
import { nextTick } from 'vue';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('modal copy button', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(ModalCopyButton, {
      propsData: {
        text: 'copy me',
        title: 'Copy this value',
        id: 'test-id',
      },
    });
  });

  describe('clipboard', () => {
    it('should fire a `success` event on click', async () => {
      const root = createWrapper(wrapper.vm.$root);
      document.execCommand = jest.fn(() => true);
      window.getSelection = jest.fn(() => ({
        toString: jest.fn(() => 'test'),
        removeAllRanges: jest.fn(),
      }));
      wrapper.trigger('click');

      await nextTick();
      expect(wrapper.emitted().success).not.toBeEmpty();
      expect(document.execCommand).toHaveBeenCalledWith('copy');
      expect(root.emitted(BV_HIDE_TOOLTIP)).toEqual([['test-id']]);
    });
    it("should propagate the clipboard error event if execCommand doesn't work", async () => {
      document.execCommand = jest.fn(() => false);
      wrapper.trigger('click');

      await nextTick();
      expect(wrapper.emitted().error).not.toBeEmpty();
      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
  });
});

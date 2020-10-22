import { shallowMount, createWrapper } from '@vue/test-utils';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('modal copy button', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

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
    it('should fire a `success` event on click', () => {
      const root = createWrapper(wrapper.vm.$root);
      document.execCommand = jest.fn(() => true);
      window.getSelection = jest.fn(() => ({
        toString: jest.fn(() => 'test'),
        removeAllRanges: jest.fn(),
      }));
      wrapper.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().success).not.toBeEmpty();
        expect(document.execCommand).toHaveBeenCalledWith('copy');
        expect(root.emitted('bv::hide::tooltip')).toEqual([['test-id']]);
      });
    });
    it("should propagate the clipboard error event if execCommand doesn't work", () => {
      document.execCommand = jest.fn(() => false);
      wrapper.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted().error).not.toBeEmpty();
        expect(document.execCommand).toHaveBeenCalledWith('copy');
      });
    });
  });
});

import { shallowMount, createWrapper } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('modal copy button', () => {
  let wrapper;

  const findBtn = () => wrapper.findComponent(GlButton);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ModalCopyButton, {
      propsData: {
        text: 'copy me',
        ...props,
      },
    });
  };

  it('shows default title', () => {
    createComponent();

    expect(findBtn().attributes()).toMatchObject({
      'aria-label': 'Copy',
      title: 'Copy',
    });
  });

  it('shows custom title', () => {
    createComponent({ title: 'Copy text!' });

    expect(findBtn().attributes()).toMatchObject({
      'aria-label': 'Copy text!',
      title: 'Copy text!',
    });
  });

  describe('clipboard', () => {
    beforeEach(() => {
      createComponent({
        id: 'test-id',
      });
    });

    it('should fire a `success` event on click', async () => {
      const root = createWrapper(wrapper.vm.$root);
      document.execCommand = jest.fn(() => true);
      window.getSelection = jest.fn(() => ({
        toString: jest.fn(() => 'test'),
        removeAllRanges: jest.fn(),
      }));
      wrapper.trigger('click');

      await nextTick();
      expect(wrapper.emitted('error')).toBeUndefined();
      expect(wrapper.emitted('success')).toHaveLength(1);
      expect(document.execCommand).toHaveBeenCalledWith('copy');
      expect(root.emitted(BV_HIDE_TOOLTIP)).toEqual([['test-id']]);
    });

    it("should propagate the clipboard error event if execCommand doesn't work", async () => {
      document.execCommand = jest.fn(() => false);
      wrapper.trigger('click');

      await nextTick();
      expect(wrapper.emitted('success')).toBeUndefined();
      expect(wrapper.emitted('error')).toHaveLength(1);
      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
  });
});

import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import modalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('modal copy button', () => {
  const Component = Vue.extend(modalCopyButton);
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        text: 'copy me',
        title: 'Copy this value',
      },
      attachToDocument: true,
      sync: false,
    });
  });

  describe('clipboard', () => {
    it('should fire a `success` event on click', () => {
      document.execCommand = jest.fn(() => true);
      window.getSelection = jest.fn(() => ({
        toString: jest.fn(() => 'test'),
        removeAllRanges: jest.fn(),
      }));
      wrapper.trigger('click');
      expect(wrapper.emitted().success).not.toBeEmpty();
      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
    it("should propagate the clipboard error event if execCommand doesn't work", () => {
      document.execCommand = jest.fn(() => false);
      wrapper.trigger('click');
      expect(wrapper.emitted().error).not.toBeEmpty();
      expect(document.execCommand).toHaveBeenCalledWith('copy');
    });
  });
});

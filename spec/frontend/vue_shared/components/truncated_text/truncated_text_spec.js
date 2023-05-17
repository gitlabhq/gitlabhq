import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { __ } from '~/locale';
import TruncatedText from '~/vue_shared/components/truncated_text/truncated_text.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('TruncatedText', () => {
  let wrapper;

  const findContent = () => wrapper.findComponent({ ref: 'content' }).element;
  const findButton = () => wrapper.findComponent(GlButton);

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(TruncatedText, {
      propsData,
      directives: {
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
      stubs: {
        GlButton,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when mounted', () => {
    it('the content has class `gl-truncate-text-by-line`', () => {
      expect(findContent().classList).toContain('gl-truncate-text-by-line');
    });

    it('the content has style variables for `lines` and `mobile-lines` with the correct values', () => {
      const { style } = findContent();

      expect(style).toContain('--lines');
      expect(style.getPropertyValue('--lines')).toBe('3');
      expect(style).toContain('--mobile-lines');
      expect(style.getPropertyValue('--mobile-lines')).toBe('10');
    });

    it('the button is not visible', () => {
      expect(findButton().exists()).toBe(false);
    });
  });

  describe('when mounted with a value for the lines property', () => {
    const lines = 4;

    beforeEach(() => {
      createComponent({ lines });
    });

    it('the lines variable has the value of the passed property', () => {
      expect(findContent().style.getPropertyValue('--lines')).toBe(lines.toString());
    });
  });

  describe('when mounted with a value for the mobileLines property', () => {
    const mobileLines = 4;

    beforeEach(() => {
      createComponent({ mobileLines });
    });

    it('the lines variable has the value of the passed property', () => {
      expect(findContent().style.getPropertyValue('--mobile-lines')).toBe(mobileLines.toString());
    });
  });

  describe('when resizing and the scroll height is smaller than the offset height', () => {
    beforeEach(() => {
      getBinding(findContent(), 'gl-resize-observer').value({
        target: { scrollHeight: 10, offsetHeight: 20 },
      });
    });

    it('the button remains invisible', () => {
      expect(findButton().exists()).toBe(false);
    });
  });

  describe('when resizing and the scroll height is greater than the offset height', () => {
    beforeEach(() => {
      getBinding(findContent(), 'gl-resize-observer').value({
        target: { scrollHeight: 20, offsetHeight: 10 },
      });
    });

    it('the button becomes visible', () => {
      expect(findButton().exists()).toBe(true);
    });

    it('the button text says "show more"', () => {
      expect(findButton().text()).toBe(__('Show more'));
    });

    describe('clicking the button', () => {
      beforeEach(() => {
        findButton().trigger('click');
      });

      it('removes the `gl-truncate-text-by-line` class on the content', () => {
        expect(findContent().classList).not.toContain('gl-truncate-text-by-line');
      });

      it('toggles the button text to "Show less"', () => {
        expect(findButton().text()).toBe(__('Show less'));
      });
    });
  });
});

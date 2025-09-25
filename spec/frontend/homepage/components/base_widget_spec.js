import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BaseWidget from '~/homepage/components/base_widget.vue';

describe('BaseWidget', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BaseWidget, {
      propsData: props,
      slots: {
        default: '<div class="test-content">Test Content</div>',
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(document, 'addEventListener');
    jest.spyOn(document, 'removeEventListener');

    Object.defineProperty(document, 'hidden', {
      writable: true,
      value: false,
    });
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('lifecycle', () => {
    it('adds visibilitychange event listener on mount', () => {
      createComponent();

      expect(document.addEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        expect.any(Function),
      );
    });

    it('removes event listener on destroy', () => {
      createComponent();
      const addEventListenerCall = document.addEventListener.mock.calls.find(
        (call) => call[0] === 'visibilitychange',
      );
      const handler = addEventListenerCall[1];

      wrapper.destroy();

      expect(document.removeEventListener).toHaveBeenCalledWith('visibilitychange', handler);
    });
  });

  describe('visibility change handling', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not emit "visible" on first visibilitychange event', () => {
      document.dispatchEvent(new Event('visibilitychange'));

      expect(wrapper.emitted('visible')).toBeUndefined();
    });

    it('does not emit "visible" when document is hidden', () => {
      document.hidden = true;
      document.dispatchEvent(new Event('visibilitychange'));

      expect(wrapper.emitted('visible')).toBeUndefined();
    });

    it('emits "visible" after debounce period when document becomes visible', () => {
      let mockTime = Date.now();
      jest.spyOn(Date, 'now').mockImplementation(() => mockTime);

      document.dispatchEvent(new Event('visibilitychange'));
      expect(wrapper.emitted('visible')).toBeUndefined();

      mockTime += 6000;
      document.dispatchEvent(new Event('visibilitychange'));

      expect(wrapper.emitted('visible')).toHaveLength(1);

      Date.now.mockRestore();
    });

    it('only triggers one "visible" event for multiple quick visibility changes', () => {
      let mockTime = Date.now();
      jest.spyOn(Date, 'now').mockImplementation(() => mockTime);

      document.dispatchEvent(new Event('visibilitychange'));
      expect(wrapper.emitted('visible')).toBeUndefined();

      document.dispatchEvent(new Event('visibilitychange'));
      document.dispatchEvent(new Event('visibilitychange'));
      document.dispatchEvent(new Event('visibilitychange'));

      mockTime += 3000;
      expect(wrapper.emitted('visible')).toBeUndefined();

      mockTime += 3000;
      document.dispatchEvent(new Event('visibilitychange'));

      expect(wrapper.emitted('visible')).toHaveLength(1);

      Date.now.mockRestore();
    });

    it('triggers another "visible" event after waiting for debounce period', () => {
      let mockTime = Date.now();
      jest.spyOn(Date, 'now').mockImplementation(() => mockTime);

      document.dispatchEvent(new Event('visibilitychange'));

      mockTime += 6000;
      document.dispatchEvent(new Event('visibilitychange'));
      expect(wrapper.emitted('visible')).toHaveLength(1);

      mockTime += 6000;
      document.dispatchEvent(new Event('visibilitychange'));
      expect(wrapper.emitted('visible')).toHaveLength(2);

      Date.now.mockRestore();
    });
  });

  describe('styling', () => {
    it('applies default styling by default', () => {
      createComponent();

      expect(wrapper.classes()).toContain('gl-border');
      expect(wrapper.classes()).toContain('gl-rounded-pill');
      expect(wrapper.classes()).toContain('gl-p-5');
    });

    it('applies default styling when applyDefaultStyling is true', () => {
      createComponent({ applyDefaultStyling: true });

      expect(wrapper.classes()).toContain('gl-border');
      expect(wrapper.classes()).toContain('gl-rounded-pill');
      expect(wrapper.classes()).toContain('gl-p-5');
    });

    it('does not apply default styling when applyDefaultStyling is false', () => {
      createComponent({ applyDefaultStyling: false });

      expect(wrapper.classes()).not.toContain('gl-border');
      expect(wrapper.classes()).not.toContain('gl-rounded-pill');
      expect(wrapper.classes()).not.toContain('gl-p-5');
    });
  });

  describe('slot rendering', () => {
    it('renders slot content', () => {
      createComponent();

      expect(wrapper.find('.test-content').exists()).toBe(true);
      expect(wrapper.find('.test-content').text()).toBe('Test Content');
    });
  });
});

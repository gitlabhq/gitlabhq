import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import VisibilityChangeDetector from '~/homepage/components/visibility_change_detector.vue';
import waitForPromises from 'helpers/wait_for_promises';

describe('VisibilityChangeDetector', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(VisibilityChangeDetector, {
      slots: {
        default: '<div class="test-content">Test Content</div>',
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(document, 'addEventListener');
    jest.spyOn(document, 'removeEventListener');
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('lifecycle', () => {
    it('adds visibility change event listener on mount', () => {
      createComponent();

      expect(document.addEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        wrapper.vm.handleVisibilityChanged,
      );
    });

    it('removes visibility change event listener on destroy', () => {
      createComponent();

      wrapper.destroy();

      expect(document.removeEventListener).toHaveBeenCalledWith(
        'visibilitychange',
        wrapper.vm.handleVisibilityChanged,
      );
    });
  });

  describe('visibility change handling', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits `visible` event when document becomes visible', async () => {
      document.dispatchEvent(new Event('visibilitychange'));
      await waitForPromises();

      expect(wrapper.emitted('visible')).toHaveLength(1);
    });

    it('does not emit visible event when document is hidden', async () => {
      Object.defineProperty(document, 'hidden', {
        writable: true,
        value: true,
      });

      document.dispatchEvent(new Event('visibilitychange'));
      await waitForPromises();

      expect(wrapper.emitted('visible')).toBeUndefined();
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

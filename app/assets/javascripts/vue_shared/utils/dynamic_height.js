import { debounce } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

/**
 * Dynamic height utility for elements that need to fill available viewport space.
 * Can be used by both Vue components (via directive) and plain JavaScript classes.
 */
export class DynamicHeightManager {
  constructor(element, options = {}) {
    this.element = element;
    this.options = {
      closest: '.content-wrapper',
      minHeight: 500,
      debounce: 100,
      ...options,
    };
    this.resizeObserver = null;
    this.debouncedSetHeight = debounce(() => {
      this.setHeight();
    }, this.options.debounce);
  }

  init() {
    if (!this.element || this.resizeObserver) return;

    // Initial height calculation
    this.setHeight();

    // Set up ResizeObserver for dynamic updates
    this.resizeObserver = new ResizeObserver(() => {
      this.debouncedSetHeight();
    });

    this.resizeObserver.observe(document.documentElement);
  }

  setHeight() {
    if (!this.element) return;

    const contentWrapper = this.element.closest(this.options.closest);

    if (!contentWrapper) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      Sentry.captureException(new Error('Content wrapper not found'), {
        extra: {
          element: this.element,
          options: this.options,
        },
      });

      return;
    }

    // Use getBoundingClientRect() to get exact decimal values to prevent rounding errors
    const contentWrapperHeight = contentWrapper?.getBoundingClientRect().height || 0;
    const elementHeight = this.element.getBoundingClientRect().height;
    const contentHeight = contentWrapperHeight - elementHeight;

    this.element.style.height = `max(calc(100vh - ${contentHeight}px), ${this.options.minHeight}px)`;
  }

  updateOptions(newOptions) {
    this.options = { ...this.options, ...newOptions };

    // Update debounced function if debounce value changed
    if (newOptions.debounce !== undefined) {
      this.debouncedSetHeight = debounce(() => {
        this.setHeight();
      }, this.options.debounce);
    }

    this.setHeight();
  }

  destroy() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }
  }
}

/**
 * Convenience function to create and initialize a DynamicHeightManager
 * @param {Element} element - The DOM element to manage
 * @param {Object} options - Configuration options
 * @returns {DynamicHeightManager} The manager instance
 */
export function createDynamicHeightManager(element, options = {}) {
  const manager = new DynamicHeightManager(element, options);
  manager.init();
  return manager;
}

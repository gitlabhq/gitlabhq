<script>
/**
 * A utility component that attaches event listeners to DOM elements matching a CSS selector.
 *
 * This component provides two modes of operation:
 * 1. Direct attachment (default): Finds existing elements and attaches listeners directly
 * 2. Event delegation: Uses document-level event delegation to handle dynamically added elements
 *
 * @example
 * <!-- Direct attachment (default) -->
 * <dom-element-listener selector="#my-button" @click="handleClick" />
 *
 * @example
 * <!-- Event delegation for elements that may not exist yet -->
 * <dom-element-listener
 *   selector="#dynamic-button"
 *   :use-event-delegation="true"
 *   @click="handleClick"
 * />
 */
export default {
  props: {
    /**
     * CSS selector string to target DOM elements.
     * Can be any valid CSS selector (e.g., '#id', '.class', '[data-attr]').
     */
    selector: {
      type: String,
      required: true,
    },
    /**
     * Whether to use event delegation instead of direct element attachment.
     *
     * Use event delegation when:
     * - Target elements may not exist when this component mounts
     * - Elements are added/removed dynamically
     * - There's a race condition between component mounting and element creation
     *
     * Event delegation attaches listeners to the document and uses event.target.closest()
     * to check if the event originated from a matching element.
     */
    useEventDelegation: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  mounted() {
    if (this.useEventDelegation) {
      /**
       * Event delegation mode: Attach listeners to document root.
       * This handles cases where target elements don't exist yet or are added dynamically.
       */
      this.disposables = Object.entries(this.$listeners).map(([eventType, handler]) => {
        const delegatedHandler = (event) => {
          // Check if clicked element matches selector or is inside matching element
          const target = event.target.closest(this.selector);
          if (target) {
            handler(event);
          }
        };

        // Use capture phase (true) for better event handling control
        document.addEventListener(eventType, delegatedHandler, true);

        // Return cleanup function
        return () => {
          document.removeEventListener(eventType, delegatedHandler, true);
        };
      });
    } else {
      /**
       * Direct attachment mode: Find existing elements and attach listeners directly.
       * This is the original behavior and works well when elements exist at mount time.
       */
      this.disposables = Array.from(document.querySelectorAll(this.selector)).flatMap((button) => {
        return Object.entries(this.$listeners).map(([key, value]) => {
          button.addEventListener(key, value);
          return () => {
            button.removeEventListener(key, value);
          };
        });
      });
    }
  },
  destroyed() {
    /**
     * Clean up all event listeners to prevent memory leaks.
     * Each disposable function removes its corresponding event listener.
     */
    this.disposables.forEach((x) => {
      x();
    });
  },
  render() {
    return this.$scopedSlots.default?.();
  },
};
</script>

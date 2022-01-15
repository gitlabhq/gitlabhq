/**
 * An event hub with a Vue instance like API
 *
 * NOTE: This is a derivative work from [mitt][1] v1.2.0 which is licensed by
 * [MIT License][2] © [Jason Miller][3]
 *
 * [1]: https://github.com/developit/mitt
 * [2]: https://opensource.org/licenses/MIT
 * [3]: https://jasonformat.com/
 */
class EventHub {
  constructor() {
    this.$_all = new Map();
  }

  dispose() {
    this.$_all.clear();
  }

  /**
   * Register an event handler for the given type.
   *
   * @param {string|symbol} type Type of event to listen for
   * @param {Function} handler Function to call in response to given event
   */
  $on(type, handler) {
    const handlers = this.$_all.get(type);
    const added = handlers && handlers.push(handler);

    if (!added) {
      this.$_all.set(type, [handler]);
    }
  }

  /**
   * Remove an event handler or all handlers for the given type.
   *
   * @param {string|symbol} type Type of event to unregister `handler`
   * @param {Function} handler Handler function to remove
   */
  $off(type, handler) {
    const handlers = this.$_all.get(type) || [];

    const newHandlers = handler ? handlers.filter((x) => x !== handler) : [];

    if (newHandlers.length) {
      this.$_all.set(type, newHandlers);
    } else {
      this.$_all.delete(type);
    }
  }

  /**
   * Add an event listener to type but only trigger it once
   *
   * @param {string|symbol} type Type of event to listen for
   * @param {Function} handler Handler function to call in response to event
   */
  $once(type, handler) {
    const wrapHandler = (...args) => {
      this.$off(type, wrapHandler);
      handler(...args);
    };
    this.$on(type, wrapHandler);
  }

  /**
   * Invoke all handlers for the given type.
   *
   * @param {string|symbol} type The event type to invoke
   * @param {Any} [evt] Any value passed to each handler
   */
  $emit(type, ...args) {
    const handlers = this.$_all.get(type) || [];

    handlers.forEach((handler) => {
      handler(...args);
    });
  }
}

/**
 * Return a Vue like event hub
 *
 * - $on
 * - $off
 * - $once
 * - $emit
 *
 * We'd like to shy away from using a full fledged Vue instance from this in the future.
 */
export default () => {
  return new EventHub();
};

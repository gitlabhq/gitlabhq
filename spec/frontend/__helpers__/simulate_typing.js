/**
 * Simulates rapid typing by emitting incremental events for each character.
 * Useful for testing debounce behavior in search components.
 *
 * @param {Object} emitter - Vue component instance with $emit method
 * @param {string} text - The full text to "type"
 * @param {string} eventName - The event name to emit (default: 'search')
 *
 * @example
 * // Emits: 't', 'te', 'tes', 'test'
 * simulateRapidTyping(findGlDropdown().vm, 'test');
 *
 * @example
 * // With custom event name
 * simulateRapidTyping(wrapper.vm, 'query', 'input');
 */
export const simulateRapidTyping = (emitter, text, eventName = 'search') => {
  for (let i = 1; i <= text.length; i += 1) {
    emitter.$emit(eventName, text.slice(0, i));
  }
};

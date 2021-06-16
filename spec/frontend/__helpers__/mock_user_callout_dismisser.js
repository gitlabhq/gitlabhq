/**
 * Mock factory for the UserCalloutDismisser component.
 * @param {slotProps} The slot props to pass to the default slot content.
 * @returns {VueComponent}
 */
export const makeMockUserCalloutDismisser = ({
  dismiss = () => {},
  shouldShowCallout = true,
} = {}) => ({
  render() {
    return this.$scopedSlots.default({
      dismiss,
      shouldShowCallout,
    });
  },
});

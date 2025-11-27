import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

/**
 * Mock factory for the UserCalloutDismisser component.
 * @param {slotProps} The slot props to pass to the default slot content.
 * @returns {VueComponent}
 */
export const makeMockUserCalloutDismisser = ({
  dismiss = () => {},
  shouldShowCallout = true,
} = {}) => ({
  props: UserCalloutDismisser.props,
  data() {
    return {
      shouldShowCallout,
      dismiss,
    };
  },
  mounted() {
    this.$emit('queryResult', { shouldShowCallout });
  },
  render() {
    return this.$scopedSlots.default({
      dismiss,
      shouldShowCallout,
    });
  },
});

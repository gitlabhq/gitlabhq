import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

/**
 * Mock factory for the UserCalloutDismisser component.
 * @param {slotProps} The slot props to pass to the default slot content.
 * @returns {VueComponent}
 */
export const makeMockUserCalloutDismisser = ({
  dismiss = () => {},
  shouldShowCallout = true,
  isLoadingQuery = false,
} = {}) => ({
  props: UserCalloutDismisser.props,
  data() {
    return {
      isLoadingQuery,
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
      isLoadingQuery,
    });
  },
});

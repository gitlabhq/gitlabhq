import UserGroupCalloutDismisser from '~/vue_shared/components/user_group_callout_dismisser.vue';

/**
 * Mock factory for the UserGroupCalloutDismisser component.
 * @param {slotProps} The slot props to pass to the default slot content.
 * @returns {VueComponent}
 */
export const makeMockUserGroupCalloutDismisser = ({
  dismiss = () => {},
  shouldShowCallout = true,
  isLoadingQuery = false,
} = {}) => ({
  props: UserGroupCalloutDismisser.props,
  data() {
    return {
      isLoadingQuery,
      shouldShowCallout,
      dismiss,
    };
  },
  render() {
    return this.$scopedSlots.default({
      dismiss,
      shouldShowCallout,
      isLoadingQuery,
    });
  },
});

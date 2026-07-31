import UserGroupCalloutDismisser from '~/vue_shared/components/user_group_callout_dismisser.vue';
import { getSlotFunction } from '~/lib/utils/vue3compat/normalize_render';

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
  // Vue 3-style zero-arg render; opt out of @vue/compat's legacy
  // render-function emulation, which misclassifies it.
  compatConfig: { RENDER_FUNCTION: false },
  render() {
    return getSlotFunction(this)({
      dismiss,
      shouldShowCallout,
      isLoadingQuery,
    });
  },
});

import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { getSlotFunction } from '~/lib/utils/vue3compat/normalize_render';

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
  // Vue 3-style zero-arg render; opt out of @vue/compat's legacy
  // render-function emulation, which misclassifies it.
  compatConfig: { RENDER_FUNCTION: false },
  render() {
    return getSlotFunction(this)({
      dismiss,
      shouldShowCallout,
    });
  },
});

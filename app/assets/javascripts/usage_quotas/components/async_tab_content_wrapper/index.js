import TabContentLoadingIndicator from './tab_content_loading_indicator.vue';
import TabContentLoadingError from './tab_content_loading_error.vue';

/**
 * Creates a wrapper for async components to show loading and error states
 * https://v2.vuejs.org/v2/guide/components-dynamic-async#Async-Components
 */

export const createAsyncTabContentWrapper = (component) => {
  return {
    loading: TabContentLoadingIndicator,
    error: TabContentLoadingError,
    component,
  };
};

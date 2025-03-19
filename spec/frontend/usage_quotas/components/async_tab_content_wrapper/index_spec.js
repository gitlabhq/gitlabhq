import { createAsyncTabContentWrapper } from '~/usage_quotas/components/async_tab_content_wrapper/';
import TabContentLoadingIndicator from '~/usage_quotas/components/async_tab_content_wrapper/tab_content_loading_indicator.vue';
import TabContentLoadingError from '~/usage_quotas/components/async_tab_content_wrapper/tab_content_loading_error.vue';

describe('createAsyncTabContentWrapper', () => {
  it('creates a config', () => {
    const component = {};
    const result = createAsyncTabContentWrapper(component);

    expect(result).toEqual({
      component,
      loading: TabContentLoadingIndicator,
      error: TabContentLoadingError,
    });
  });
});

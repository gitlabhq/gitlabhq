import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import TestSummaryPage from '~/merge_requests/reports/test_summary/test_summary_page.vue';
import TestSummaryProvider from '~/merge_requests/reports/test_summary/test_summary_provider.vue';
import TestSummaryContent from '~/merge_requests/reports/test_summary/test_summary_content.vue';

describe('TestSummaryPage', () => {
  const { bindInternalEventDocument } = useMockInternalEventsTracking();
  const mr = { testResultsPath: '/test_reports.json' };

  it('renders TestSummaryContent inside TestSummaryProvider and tracks the view', () => {
    const wrapper = shallowMountExtended(TestSummaryPage, { propsData: { mr } });
    const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
    const provider = wrapper.findComponent(TestSummaryProvider);

    expect(provider.props('mr')).toBe(mr);
    expect(provider.findComponent(TestSummaryContent).exists()).toBe(true);
    expect(trackEventSpy).toHaveBeenCalledWith(
      'view_merge_request_report',
      { label: 'test_summary' },
      undefined,
    );
  });
});

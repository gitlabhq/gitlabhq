import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TestSummaryNavItem from '~/merge_requests/reports/test_summary/test_summary_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('TestSummaryNavItem', () => {
  it('renders the test summary route with the injected loading state and icon', () => {
    const wrapper = shallowMountExtended(TestSummaryNavItem, {
      provide: {
        isTestSummaryLoading: true,
        statusIconName: 'warning',
      },
    });
    const reportListItem = wrapper.findComponent(ReportListItem);

    expect(reportListItem.text()).toBe('Test summary');
    expect(reportListItem.props()).toMatchObject({
      to: 'test-summary',
      isLoading: true,
      statusIcon: 'warning',
    });
  });
});

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AccessibilityNavItem from '~/merge_requests/reports/accessibility/accessibility_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('AccessibilityNavItem', () => {
  it('links to the accessibility route with the injected loading state and icon', () => {
    const wrapper = shallowMountExtended(AccessibilityNavItem, {
      provide: { isAccessibilityLoading: true, statusIconName: 'warning' },
    });
    const item = wrapper.findComponent(ReportListItem);

    expect(item.text()).toBe('Accessibility');
    expect(item.props()).toMatchObject({
      to: 'accessibility',
      isLoading: true,
      statusIcon: 'warning',
    });
  });
});

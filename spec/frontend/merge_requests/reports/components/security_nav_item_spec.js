import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SecurityNavItem from '~/merge_requests/reports/components/security_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('SecurityNavItem', () => {
  let wrapper;

  const findReportListItem = () => wrapper.findComponent(ReportListItem);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(SecurityNavItem, {
      provide: {
        isLoadingScans: false,
        statusIconName: 'success',
        ...provide,
      },
    });
  };

  describe('ReportListItem', () => {
    it('renders with correct route', () => {
      createComponent();

      expect(findReportListItem().props('to')).toBe('security-scan');
    });

    it('renders "Security scan" text', () => {
      createComponent();

      expect(findReportListItem().text()).toBe('Security scan');
    });

    it('passes isLoading true when isLoadingScans is true', () => {
      createComponent({ provide: { isLoadingScans: true } });

      expect(findReportListItem().props('isLoading')).toBe(true);
    });

    it('passes isLoading false when isLoadingScans is false', () => {
      createComponent();

      expect(findReportListItem().props('isLoading')).toBe(false);
    });
  });

  describe('statusIconName', () => {
    it('passes statusIconName to ReportListItem', () => {
      createComponent({ provide: { statusIconName: 'error' } });

      expect(findReportListItem().props('statusIcon')).toBe('error');
    });

    it('passes warning icon', () => {
      createComponent({ provide: { statusIconName: 'warning' } });

      expect(findReportListItem().props('statusIcon')).toBe('warning');
    });

    it('passes success icon by default', () => {
      createComponent();

      expect(findReportListItem().props('statusIcon')).toBe('success');
    });
  });
});

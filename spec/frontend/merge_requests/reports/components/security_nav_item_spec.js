import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SecurityNavItem from '~/merge_requests/reports/components/security_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('SecurityNavItem', () => {
  let wrapper;

  const findReportListItem = () => wrapper.findComponent(ReportListItem);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(SecurityNavItem, {
      provide: {
        totalNewFindings: 0,
        isLoading: false,
        topLevelErrorMessage: '',
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

    it('passes isLoading to ReportListItem', () => {
      createComponent({ provide: { isLoading: true } });

      expect(findReportListItem().props('isLoading')).toBe(true);
    });
  });

  describe('statusIcon', () => {
    it('returns error icon when topLevelErrorMessage is set', () => {
      createComponent({ provide: { topLevelErrorMessage: 'Error occurred' } });

      expect(findReportListItem().props('statusIcon')).toBe('error');
    });

    it('returns warning icon when totalNewFindings > 0', () => {
      createComponent({ provide: { totalNewFindings: 5 } });

      expect(findReportListItem().props('statusIcon')).toBe('warning');
    });

    it('returns success icon when no error and no findings', () => {
      createComponent();

      expect(findReportListItem().props('statusIcon')).toBe('success');
    });

    it('shows error icon when both error and findings are present', () => {
      createComponent({
        provide: {
          topLevelErrorMessage: 'Error occurred',
          totalNewFindings: 5,
        },
      });

      expect(findReportListItem().props('statusIcon')).toBe('error');
    });
  });
});

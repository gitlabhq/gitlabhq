import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeQualityNavItem from '~/merge_requests/reports/code_quality/code_quality_nav_item.vue';
import ReportListItem from '~/merge_requests/reports/components/report_list_item.vue';

describe('CodeQualityNavItem', () => {
  let wrapper;

  const findReportListItem = () => wrapper.findComponent(ReportListItem);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CodeQualityNavItem, {
      provide: {
        isCodeQualityLoading: false,
        statusIconName: 'success',
        ...provide,
      },
    });
  };

  describe('ReportListItem', () => {
    it('renders with correct route and text', () => {
      createComponent();

      expect(findReportListItem().text()).toBe('Code quality');
      expect(findReportListItem().props('to')).toBe('code-quality');
    });

    it('passes isLoading to ReportListItem', () => {
      createComponent({ provide: { isCodeQualityLoading: true } });

      expect(findReportListItem().props('isLoading')).toBe(true);
    });
  });

  describe('statusIconName', () => {
    it('passes injected statusIconName to ReportListItem', () => {
      createComponent({ provide: { statusIconName: 'some-icon' } });

      expect(findReportListItem().props('statusIcon')).toBe('some-icon');
    });
  });
});

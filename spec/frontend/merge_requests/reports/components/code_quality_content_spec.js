import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CodeQualityContent from '~/merge_requests/reports/components/code_quality_content.vue';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import { codeQualitySummary } from '~/vue_merge_request_widget/widgets/code_quality/utils';

jest.mock('~/vue_merge_request_widget/widgets/code_quality/utils');

describe('CodeQualityContent', () => {
  let wrapper;

  const MOCK_SECTIONS = [
    {
      children: [
        {
          text: 'Major - Method has too many lines',
          icon: { name: 'severityMedium' },
          link: { href: '#', text: 'in src/foo.js:42' },
        },
      ],
    },
  ];

  const DEFAULT_PROVIDE = {
    isCodeQualityLoading: false,
    statusMessage: '',
    errorMessage: '',
    newErrorsCount: 2,
    resolvedErrorsCount: 1,
    statusIconName: 'warning',
    sections: MOCK_SECTIONS,
  };

  const findReportSection = () => wrapper.findComponent(ReportSection);

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(CodeQualityContent, {
      provide: {
        ...DEFAULT_PROVIDE,
        ...provide,
      },
    });
  };

  describe('rendering', () => {
    it('renders ReportSection', () => {
      createComponent();

      expect(findReportSection().exists()).toBe(true);
    });
  });

  describe('loading', () => {
    it('passes isLoading to ReportSection', () => {
      createComponent({ provide: { isCodeQualityLoading: true } });

      expect(findReportSection().props('isLoading')).toBe(true);
    });

    it('passes loading text to ReportSection', () => {
      createComponent();

      expect(findReportSection().props('loadingText')).toBe('Code quality is loading');
    });
  });

  describe('summary text', () => {
    it('calls codeQualitySummary with newErrorsCount and resolvedErrorsCount', () => {
      createComponent({ provide: { newErrorsCount: 2, resolvedErrorsCount: 1 } });

      expect(codeQualitySummary).toHaveBeenCalledWith({ newCount: 2, resolvedCount: 1 });
    });
  });

  describe('error handling', () => {
    const errorMessage = 'Code quality failed loading results';
    const statusMessage = 'This merge request does not have codequality reports';

    it('shows error message as summary text when errorMessage is set', () => {
      createComponent({
        provide: { errorMessage, statusIconName: 'error' },
      });

      expect(codeQualitySummary).not.toHaveBeenCalled();
      expect(findReportSection().props('summary').title).toBe(errorMessage);
    });

    it('shows status message as summary text when statusMessage is set', () => {
      createComponent({
        provide: { statusMessage, statusIconName: 'warning' },
      });

      expect(codeQualitySummary).not.toHaveBeenCalled();
      expect(findReportSection().props('summary').title).toBe(statusMessage);
    });

    it('shows statusMessage over errorMessage when both are set', () => {
      createComponent({
        provide: { statusMessage, errorMessage, statusIconName: 'warning' },
      });

      expect(codeQualitySummary).not.toHaveBeenCalled();
      expect(findReportSection().props('summary').title).toBe(statusMessage);
    });
  });

  describe('sections', () => {
    it('passes sections from provider to ReportSection', () => {
      createComponent();

      expect(findReportSection().props('sections')).toBe(MOCK_SECTIONS);
    });

    it('passes an empty sections array to ReportSection', () => {
      createComponent({ provide: { sections: [] } });

      expect(findReportSection().props('sections')).toEqual([]);
    });
  });

  describe('status icon', () => {
    it('passes statusIconName from provider', () => {
      createComponent({ provide: { statusIconName: 'success' } });

      expect(findReportSection().props('statusIconName')).toBe('success');
    });
  });
});

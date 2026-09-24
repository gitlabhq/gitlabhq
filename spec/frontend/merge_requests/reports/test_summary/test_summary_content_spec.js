import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TestSummaryContent from '~/merge_requests/reports/test_summary/test_summary_content.vue';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';
import TestCaseDetails from '~/ci/pipeline_details/test_reports/test_case_details.vue';
import { parseTestReport } from '~/vue_merge_request_widget/widgets/test_report/utils';
import newFailedTestReports from 'jest/ci/reports/mock_data/new_failures_report.json';
import successTestReports from 'jest/ci/reports/mock_data/no_failures_report.json';

describe('TestSummaryContent', () => {
  let wrapper;

  const findReportSection = () => wrapper.findComponent(ReportSection);
  const findTestCaseDetails = () => wrapper.findComponent(TestCaseDetails);

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(TestSummaryContent, {
      provide: {
        isTestSummaryLoading: false,
        statusMessage: '',
        errorMessage: '',
        statusIconName: 'warning',
        testReport: parseTestReport(newFailedTestReports),
        fullReportPath: '/pipelines/5/test_report',
        headBlobPath: '/blob/abc',
        ...provide,
      },
    });
  };

  it('passes the report summary and action buttons to ReportSection', () => {
    createComponent();

    expect(findReportSection().props()).toMatchObject({
      isLoading: false,
      loadingText: 'Test summary results are being parsed',
      statusIconName: 'warning',
      summary: {
        title:
          'Test summary: %{strong_start}2%{strong_end} failed, %{strong_start}11%{strong_end} total tests',
      },
    });
    expect(findReportSection().props('actionButtons')).toMatchObject([
      { text: 'Copy failed tests', dataClipboardText: 'spec/file_1.rb spec/file_2.rb' },
      { text: 'Full report', href: '/pipelines/5/test_report' },
    ]);
  });

  it('omits the copy and full report buttons without new failures or a pipeline', () => {
    createComponent({ testReport: parseTestReport(successTestReports), fullReportPath: '' });

    expect(findReportSection().props('actionButtons')).toEqual([]);
  });

  it.each([
    [
      'the status message',
      { statusMessage: 'Not available', errorMessage: 'Failed' },
      'Not available',
    ],
    ['the error message', { errorMessage: 'Failed' }, 'Failed'],
  ])('summarises with %s', (_, provide, expected) => {
    createComponent(provide);

    expect(findReportSection().props('summary')).toEqual({ title: expected });
  });

  it('opens the test case details modal for a test', async () => {
    createComponent();

    const [test] = findReportSection().props('sections')[0].children;
    test.actions[0].onClick();
    await nextTick();

    expect(findTestCaseDetails().props('visible')).toBe(true);
    expect(findTestCaseDetails().props('testCase')).toMatchObject({
      name: test.text,
      filePath: '/blob/abc/spec/file_1.rb',
    });
  });
});

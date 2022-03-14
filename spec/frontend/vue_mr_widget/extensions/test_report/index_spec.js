import { GlButton } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import testReportExtension from '~/vue_merge_request_widget/extensions/test_report';
import { i18n } from '~/vue_merge_request_widget/extensions/test_report/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import httpStatusCodes from '~/lib/utils/http_status';

import { failedReport } from '../../../reports/mock_data/mock_data';
import mixedResultsTestReports from '../../../reports/mock_data/new_and_fixed_failures_report.json';
import newErrorsTestReports from '../../../reports/mock_data/new_errors_report.json';
import newFailedTestReports from '../../../reports/mock_data/new_failures_report.json';
import successTestReports from '../../../reports/mock_data/no_failures_report.json';
import resolvedFailures from '../../../reports/mock_data/resolved_failures.json';

const reportWithParsingErrors = failedReport;
reportWithParsingErrors.suites[0].suite_errors = {
  head: 'JUnit XML parsing failed: 2:24: FATAL: attributes construct error',
  base: 'JUnit data parsing failed: string not matched',
};

describe('Test report extension', () => {
  let wrapper;
  let mock;

  registerExtension(testReportExtension);

  const endpoint = '/root/repo/-/merge_requests/4/test_reports.json';

  const mockApi = (statusCode, data = mixedResultsTestReports) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findTertiaryButton = () => wrapper.find(GlButton);
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          testResultsPath: endpoint,
          headBlobPath: 'head/blob/path',
          pipeline: { path: 'pipeline/path' },
        },
      },
    });
  };

  const createExpandedWidgetWithData = async (data = mixedResultsTestReports) => {
    mockApi(httpStatusCodes.OK, data);
    createComponent();
    await waitForPromises();
    findToggleCollapsedButton().trigger('click');
    await waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(httpStatusCodes.OK);
      createComponent();

      expect(wrapper.text()).toContain(i18n.loading);
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toContain(i18n.error);
    });

    it.each`
      description                 | mockData                   | expectedResult
      ${'mixed test results'}     | ${mixedResultsTestReports} | ${'Test summary: 2 failed and 2 fixed test results, 11 total tests'}
      ${'unchanged test results'} | ${successTestReports}      | ${'Test summary: no changed test results, 11 total tests'}
      ${'tests with errors'}      | ${newErrorsTestReports}    | ${'Test summary: 2 errors, 11 total tests'}
      ${'failed test results'}    | ${newFailedTestReports}    | ${'Test summary: 2 failed, 11 total tests'}
      ${'resolved failures'}      | ${resolvedFailures}        | ${'Test summary: 4 fixed test results, 11 total tests'}
    `('displays summary text for $description', async ({ mockData, expectedResult }) => {
      mockApi(httpStatusCodes.OK, mockData);
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toContain(expectedResult);
    });

    it('displays a link to the full report', async () => {
      mockApi(httpStatusCodes.OK);
      createComponent();

      await waitForPromises();

      expect(findTertiaryButton().text()).toBe('Full report');
      expect(findTertiaryButton().attributes('href')).toBe('pipeline/path/test_report');
    });

    it('shows an error when a suite has a parsing error', async () => {
      mockApi(httpStatusCodes.OK, reportWithParsingErrors);
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toContain(i18n.error);
    });
  });

  describe('expanded data', () => {
    it('displays summary for each suite', async () => {
      await createExpandedWidgetWithData();

      expect(trimText(findAllExtensionListItems().at(0).text())).toBe(
        'rspec:pg: 1 failed and 2 fixed test results, 8 total tests',
      );
      expect(trimText(findAllExtensionListItems().at(1).text())).toBe(
        'java ant: 1 failed, 3 total tests',
      );
    });

    it('displays suite parsing errors', async () => {
      await createExpandedWidgetWithData(reportWithParsingErrors);

      const suiteText = trimText(findAllExtensionListItems().at(0).text());

      expect(suiteText).toContain(
        'Head report parsing error: JUnit XML parsing failed: 2:24: FATAL: attributes construct error',
      );
      expect(suiteText).toContain(
        'Base report parsing error: JUnit data parsing failed: string not matched',
      );
    });
  });
});

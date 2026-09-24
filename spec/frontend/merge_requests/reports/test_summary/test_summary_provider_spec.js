import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
} from '~/lib/utils/http_status';
import TestSummaryProvider from '~/merge_requests/reports/test_summary/test_summary_provider.vue';
import mixedResultsTestReports from 'jest/ci/reports/mock_data/new_and_fixed_failures_report.json';

describe('TestSummaryProvider', () => {
  let wrapper;
  let mock;

  const endpoint = '/test_reports.json';
  const pipeline = { project_full_path: 'group/project', id: 5 };

  const InjectedChild = {
    inject: [
      'isTestSummaryLoading',
      'statusMessage',
      'errorMessage',
      'statusIconName',
      'testReport',
      'fullReportPath',
    ],
    template: `
      <div>
        <span data-testid="is-loading">{{ isTestSummaryLoading }}</span>
        <span data-testid="status-message">{{ statusMessage }}</span>
        <span data-testid="error-message">{{ errorMessage }}</span>
        <span data-testid="status-icon-name">{{ statusIconName }}</span>
        <span data-testid="total">{{ testReport.summary && testReport.summary.total }}</span>
        <span data-testid="full-report-path">{{ fullReportPath }}</span>
      </div>
    `,
  };

  const mockApi = (statusCode, data, headers = {}) =>
    mock.onGet(endpoint).reply(statusCode, data, headers);

  const createComponent = ({ mr = { testResultsPath: endpoint, pipeline } } = {}) => {
    wrapper = mount(TestSummaryProvider, {
      propsData: { mr },
      slots: { default: InjectedChild },
    });
  };

  const state = () =>
    Object.fromEntries(
      [
        'is-loading',
        'status-message',
        'error-message',
        'status-icon-name',
        'total',
        'full-report-path',
      ].map((id) => [id, wrapper.find(`[data-testid="${id}"]`).text()]),
    );

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockApi(HTTP_STATUS_OK, mixedResultsTestReports);
  });

  afterEach(() => mock.restore());

  it('provides the parsed report, the warning icon and the full report path', async () => {
    createComponent();
    await waitForPromises();

    expect(state()).toEqual({
      'is-loading': 'false',
      'status-message': '',
      'error-message': '',
      'status-icon-name': 'warning',
      total: '11',
      'full-report-path': '/group/project/-/pipelines/5/test_report',
    });
  });

  it('reports no results, without fetching, when the endpoint is missing', async () => {
    createComponent({ mr: {} });
    await waitForPromises();

    expect(mock.history.get).toHaveLength(0);
    expect(state()).toMatchObject({
      'is-loading': 'false',
      'status-message': 'Test summary results are not available',
      'status-icon-name': 'warning',
      'full-report-path': '',
    });
  });

  it('shows the status reason when the fetch fails with one', async () => {
    mockApi(HTTP_STATUS_BAD_REQUEST, { status_reason: 'No test reports found' });
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'status-message': 'No test reports found',
      'status-icon-name': 'warning',
    });
  });

  it('shows the error icon when the fetch fails without a status reason', async () => {
    mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'error-message': 'Test summary failed to load results',
      'status-icon-name': 'error',
    });
  });

  describe('polling', () => {
    beforeEach(() => {
      mock.reset();
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_NO_CONTENT, '', { 'poll-interval': '1' });
      mockApi(HTTP_STATUS_OK, mixedResultsTestReports);
    });

    it('keeps polling while the report is parsed, then stops once resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(state()['is-loading']).toBe('true');

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(state()).toMatchObject({ 'is-loading': 'false', total: '11' });
      expect(mock.history.get).toHaveLength(2);
    });

    it('stops polling when destroyed', async () => {
      createComponent();
      await waitForPromises();

      wrapper.destroy();
      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(mock.history.get).toHaveLength(1);
    });
  });
});

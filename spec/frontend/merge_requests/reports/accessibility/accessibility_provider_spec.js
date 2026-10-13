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
import AccessibilityProvider from '~/merge_requests/reports/accessibility/accessibility_provider.vue';
import {
  accessibilityReportResponseErrors,
  accessibilityReportResponseSuccess,
} from 'jest/vue_merge_request_widget/widgets/accessibility/mock_data';

describe('AccessibilityProvider', () => {
  let wrapper;
  let mock;

  const endpoint = '/accessibility_reports';
  const UNAVAILABLE = {
    'is-loading': 'false',
    'status-message': 'Accessibility scanning results are not available',
    'error-message': '',
    'status-icon-name': 'warning',
  };

  const InjectedChild = {
    inject: [
      'isAccessibilityLoading',
      'errorMessage',
      'statusMessage',
      'errorCount',
      'statusIconName',
    ],
    template: `
      <div>
        <span data-testid="is-loading">{{ isAccessibilityLoading }}</span>
        <span data-testid="error-message">{{ errorMessage }}</span>
        <span data-testid="status-message">{{ statusMessage }}</span>
        <span data-testid="error-count">{{ errorCount }}</span>
        <span data-testid="status-icon-name">{{ statusIconName }}</span>
      </div>
    `,
  };

  const mockApi = (statusCode, data) => mock.onGet(endpoint).reply(statusCode, data, {});

  const createComponent = ({ mr = { accessibilityReportPath: endpoint } } = {}) => {
    wrapper = mount(AccessibilityProvider, {
      propsData: { mr },
      slots: { default: InjectedChild },
    });
  };

  const state = () =>
    Object.fromEntries(
      ['is-loading', 'error-message', 'status-message', 'error-count', 'status-icon-name'].map(
        (id) => [id, wrapper.find(`[data-testid="${id}"]`).text()],
      ),
    );

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);
  });

  afterEach(() => mock.restore());

  it('provides the error count and the warning icon for a report with errors', async () => {
    createComponent();
    await waitForPromises();

    expect(state()).toEqual({
      'is-loading': 'false',
      'error-message': '',
      'status-message': '',
      'error-count': '5',
      'status-icon-name': 'warning',
    });
  });

  it('provides the success icon when no errors were detected', async () => {
    mockApi(HTTP_STATUS_OK, accessibilityReportResponseSuccess);
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({ 'error-count': '0', 'status-icon-name': 'success' });
  });

  it('reports no results, without fetching, when the endpoint is missing', async () => {
    createComponent({ mr: {} });
    await waitForPromises();

    expect(mock.history.get).toHaveLength(0);
    expect(state()).toMatchObject(UNAVAILABLE);
  });

  // An empty 204 means the merge request has no report, which must not read as "no issues".
  it('reports no results when the response has no content', async () => {
    mock.reset();
    mock.onGet(endpoint).reply(HTTP_STATUS_NO_CONTENT, '', {});
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject(UNAVAILABLE);
  });

  it('shows the status reason when the fetch fails with one', async () => {
    mockApi(HTTP_STATUS_BAD_REQUEST, { status_reason: 'No accessibility reports found' });
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'status-message': 'No accessibility reports found',
      'status-icon-name': 'warning',
    });
  });

  it('shows the error icon when the fetch fails without a status reason', async () => {
    mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'error-message': 'Accessibility scanning failed loading results',
      'status-icon-name': 'error',
    });
  });

  describe('polling', () => {
    beforeEach(() => {
      mock.reset();
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_NO_CONTENT, '', { 'poll-interval': '1' });
      mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);
    });

    it('keeps polling while parsing, then stops once resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(state()['is-loading']).toBe('true');

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(state()).toMatchObject({ 'is-loading': 'false', 'error-count': '5' });
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

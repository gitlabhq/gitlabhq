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
import TerraformProvider from '~/merge_requests/reports/terraform/terraform_provider.vue';
import {
  plans,
  validPlanWithName,
  validPlanFewChanges,
} from 'jest/vue_merge_request_widget/components/terraform/mock_data';

describe('TerraformProvider', () => {
  let wrapper;
  let mock;

  const endpoint = '/terraform_reports';
  const UNAVAILABLE = {
    'is-loading': 'false',
    'status-message': 'Terraform reports are not available',
    'status-icon-name': 'warning',
  };

  const InjectedChild = {
    inject: ['isTerraformLoading', 'statusMessage', 'reportSummary', 'statusIconName', 'sections'],
    template: `
      <div>
        <span data-testid="is-loading">{{ isTerraformLoading }}</span>
        <span data-testid="status-message">{{ statusMessage }}</span>
        <span data-testid="summary-json">{{ JSON.stringify(reportSummary) }}</span>
        <span data-testid="status-icon-name">{{ statusIconName }}</span>
        <span data-testid="sections-json">{{ JSON.stringify(sections) }}</span>
      </div>
    `,
  };

  const mockApi = (statusCode, data) => mock.onGet(endpoint).reply(statusCode, data, {});

  const createComponent = ({ mr = { terraformReportsPath: endpoint } } = {}) => {
    wrapper = mount(TerraformProvider, {
      propsData: { mr },
      slots: { default: InjectedChild },
    });
  };

  const getText = (testId) => wrapper.find(`[data-testid="${testId}"]`).text();
  const state = () =>
    Object.fromEntries(
      ['is-loading', 'status-message', 'status-icon-name'].map((id) => [id, getText(id)]),
    );
  const findSummary = () => JSON.parse(getText('summary-json'));
  const findSections = () => JSON.parse(getText('sections-json'));

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockApi(HTTP_STATUS_OK, plans);
  });

  afterEach(() => mock.restore());

  it('provides one section holding the valid reports ahead of the invalid ones', async () => {
    createComponent();
    await waitForPromises();

    expect(findSections().map(({ children }) => children.map((child) => child.icon.name))).toEqual([
      ['success', 'success', 'success', 'success', 'error', 'error'],
    ]);
    expect(findSummary()).toEqual({
      title: '%{strong_start}4%{strong_end} Terraform reports were generated in your pipelines',
      subtitle: '%{strong_start}2%{strong_end} Terraform reports failed to generate',
    });
    expect(state()).toEqual({
      'is-loading': 'false',
      'status-message': '',
      'status-icon-name': 'warning',
    });
  });

  it('provides the success icon when every report generated', async () => {
    mockApi(HTTP_STATUS_OK, { valid_plan_one: validPlanWithName });
    createComponent();
    await waitForPromises();

    expect(findSummary().subtitle).toBeUndefined();
    expect(state()).toMatchObject({ 'status-icon-name': 'success' });
  });

  it('orders the reports by descending resource change count', async () => {
    mockApi(HTTP_STATUS_OK, {
      valid_plan_few_changes: validPlanFewChanges,
      valid_plan_one: validPlanWithName,
    });
    createComponent();
    await waitForPromises();

    expect(findSections()[0].children.map((child) => child.text)).toEqual([
      'The job %{strong_start}Valid Plan%{strong_end} generated a report.',
      'The job %{strong_start}Valid Plan - few changes%{strong_end} generated a report.',
    ]);
  });

  it('reports no results, without fetching, when the endpoint is missing', async () => {
    createComponent({ mr: {} });
    await waitForPromises();

    expect(mock.history.get).toHaveLength(0);
    expect(state()).toMatchObject(UNAVAILABLE);
  });

  it('reports no results when the response has no content', async () => {
    mock.reset();
    mock.onGet(endpoint).reply(HTTP_STATUS_NO_CONTENT, '', {});
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject(UNAVAILABLE);
    expect(findSections()).toEqual([]);
  });

  it('shows the status reason when the fetch fails with one', async () => {
    mockApi(HTTP_STATUS_BAD_REQUEST, { status_reason: 'No terraform reports found' });
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'status-message': 'No terraform reports found',
      'status-icon-name': 'warning',
    });
  });

  it('shows the error icon when the fetch fails without a status reason', async () => {
    mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
    createComponent();
    await waitForPromises();

    expect(state()).toMatchObject({
      'status-message': 'Failed to load Terraform reports',
      'status-icon-name': 'error',
    });
  });

  describe('polling', () => {
    beforeEach(() => {
      mock.reset();
      mock.onGet(endpoint).replyOnce(HTTP_STATUS_NO_CONTENT, '', { 'poll-interval': '1' });
      mockApi(HTTP_STATUS_OK, plans);
    });

    it('keeps polling while parsing, then stops once resolved', async () => {
      createComponent();
      await waitForPromises();

      expect(state()['is-loading']).toBe('true');

      jest.runOnlyPendingTimers();
      await waitForPromises();

      expect(state()['is-loading']).toBe('false');
      expect(findSections()[0].children).toHaveLength(6);
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

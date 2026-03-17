import MockAdapter from 'axios-mock-adapter';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import CodeQualityProvider from '~/merge_requests/reports/components/code_quality_provider.vue';

describe('CodeQualityProvider', () => {
  let wrapper;
  let mock;

  const DEFAULT_MR_PROPS = {
    codequalityReportsPath: '/codequality_reports',
  };

  const emptyResponse = {
    new_errors: [],
    existing_errors: [],
    resolved_errors: [],
  };

  const responseWithNewErrors = {
    new_errors: [
      { description: 'Method has too many lines', severity: 'major' },
      { description: 'Cyclomatic complexity is too high', severity: 'minor' },
    ],
    existing_errors: [],
    resolved_errors: [],
  };

  const InjectedChild = {
    inject: ['isCodeQualityLoading', 'errorMessage', 'newErrorsCount', 'statusIconName'],
    template: `
      <div data-testid="child">
        <span data-testid="is-loading">{{ isCodeQualityLoading }}</span>
        <span data-testid="error-message">{{ errorMessage }}</span>
        <span data-testid="new-errors-count">{{ newErrorsCount }}</span>
        <span data-testid="status-icon-name">{{ statusIconName }}</span>
      </div>
    `,
  };

  const mockApi = (statusCode, data) => {
    mock.onGet(DEFAULT_MR_PROPS.codequalityReportsPath).reply(statusCode, data, {});
  };

  const createComponent = ({ mr = DEFAULT_MR_PROPS } = {}) => {
    wrapper = mount(CodeQualityProvider, {
      propsData: { mr },
      slots: {
        default: InjectedChild,
      },
    });
  };

  const findByTestId = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const getTextByTestId = (testId) => findByTestId(testId).text();
  const findIsLoading = () => getTextByTestId('is-loading');
  const findErrorMessage = () => getTextByTestId('error-message');
  const findStatusIconName = () => getTextByTestId('status-icon-name');
  const findNewErrorsCount = () => getTextByTestId('new-errors-count');

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockApi(HTTP_STATUS_OK, responseWithNewErrors);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('rendering', () => {
    it('renders slot content', async () => {
      createComponent();
      await waitForPromises();

      expect(findByTestId('child').exists()).toBe(true);
    });
  });

  describe('data fetching', () => {
    it('does not fetch when code quality endpoint is missing', async () => {
      createComponent({ mr: {} });
      await waitForPromises();

      expect(mock.history.get).toHaveLength(0);
      expect(findErrorMessage()).toBe('Code quality results are not available');
      expect(findStatusIconName()).toBe('error');
      expect(findIsLoading()).toBe('false');
    });

    describe('loading', () => {
      it('is true while the request is in progress', () => {
        createComponent();

        expect(findIsLoading()).toBe('true');
      });

      it('is false after the request completes', async () => {
        createComponent();
        await waitForPromises();

        expect(findIsLoading()).toBe('false');
      });

      it('is false when the request fails', async () => {
        mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent();
        await waitForPromises();

        expect(findIsLoading()).toBe('false');
      });
    });

    describe('response data', () => {
      it('provides new errors count from response', async () => {
        createComponent();
        await waitForPromises();

        expect(findNewErrorsCount()).toBe(String(responseWithNewErrors.new_errors.length));
      });

      it('provides zero count when no new errors', async () => {
        mockApi(HTTP_STATUS_OK, emptyResponse);
        createComponent();
        await waitForPromises();

        expect(findNewErrorsCount()).toBe('0');
      });
    });

    describe('error handling', () => {
      it('sets error message when fetch fails', async () => {
        mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent();
        await waitForPromises();

        expect(findErrorMessage()).toBe('Code quality failed loading results');
      });

      it('has no error message on success', async () => {
        createComponent();
        await waitForPromises();

        expect(findErrorMessage()).toBe('');
      });
    });

    describe('statusIconName', () => {
      it('returns error when fetch fails', async () => {
        mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        createComponent();
        await waitForPromises();

        expect(findStatusIconName()).toBe('error');
      });

      it('returns warning when new errors exist', async () => {
        createComponent();
        await waitForPromises();

        expect(findStatusIconName()).toBe('warning');
      });

      it('returns success when no new errors', async () => {
        mockApi(HTTP_STATUS_OK, emptyResponse);
        createComponent();
        await waitForPromises();

        expect(findStatusIconName()).toBe('success');
      });
    });

    describe('polling', () => {
      it('stops the poll when data is resolved', async () => {
        const stopSpy = jest.spyOn(Poll.prototype, 'stop');

        createComponent();
        await waitForPromises();

        expect(stopSpy).toHaveBeenCalled();
      });
    });
  });
});

import { GlCollapsibleListbox, GlEmptyState, GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import { TEST_HOST } from 'spec/test_constants';
import { mockTracking } from 'helpers/tracking_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import Pipelines from '~/ci/pipelines_page/pipelines_graphql.vue';
import NavigationControls from '~/ci/pipelines_page/components/nav_controls.vue';
import NoCiEmptyState from '~/ci/pipelines_page/components/empty_state/no_ci_empty_state.vue';
import PipelinesFilteredSearch from '~/ci/pipelines_page/components/pipelines_filtered_search.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import getPipelinesQuery from '~/ci/pipelines_page/graphql/queries/get_pipelines.query.graphql';
import getAllPipelinesCountQuery from '~/ci/pipelines_page/graphql/queries/get_all_pipelines_count.query.graphql';
import clearRunnerCacheMutation from '~/ci/pipelines_page/graphql/mutations/clear_runner_cache.mutation.graphql';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import * as urlUtils from '~/lib/utils/url_utility';
import { PIPELINE_ID_KEY, PIPELINE_IID_KEY, TRACKING_CATEGORIES } from '~/ci/constants';
import retryPipelineMutation from '~/ci/pipelines_page/graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from '~/ci/pipelines_page/graphql/mutations/cancel_pipeline.mutation.graphql';
import ciPipelineStatusesUpdatedSubscription from '~/ci/pipelines_page/graphql/subscriptions/ci_pipeline_statuses_updated.subscription.graphql';
import {
  setIdTypePreferenceMutationResponse,
  setIdTypePreferenceMutationResponseWithErrors,
} from 'jest/issues/list/mock_data';
import {
  mockPipelinesData,
  mockPipelinesCount,
  mockRetryPipelineMutationResponse,
  mockCancelPipelineMutationResponse,
  mockRetryFailedPipelineMutationResponse,
  mockPipelinesDataEmpty,
  mockRunnerCacheClearPayload,
  mockRunnerCacheClearPayloadWithError,
  mockPipelinesFilteredSearch,
  mockPipelineUpdateResponse,
  mockPipelineUpdateResponseEmpty,
} from './mock_data';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/ci/pipeline_details/utils', () => ({
  validateParams: jest.fn((params) => ({ ...params })),
}));

Vue.use(VueApollo);

describe('Pipelines app', () => {
  let wrapper;
  let trackingSpy;

  const countHandler = jest.fn().mockResolvedValue(mockPipelinesCount);
  const successHandler = jest.fn().mockResolvedValue(mockPipelinesData);
  const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
  const emptyHandler = jest.fn().mockResolvedValue(mockPipelinesDataEmpty);
  const subscriptionHandler = jest.fn().mockResolvedValue(mockPipelineUpdateResponse);
  const subscriptionHandlerEmpty = jest.fn().mockResolvedValue(mockPipelineUpdateResponseEmpty);
  const clearCacheMutationSuccessHandler = jest.fn().mockResolvedValue(mockRunnerCacheClearPayload);
  const clearCacheMutationFailedHandler = jest
    .fn()
    .mockResolvedValue(mockRunnerCacheClearPayloadWithError);
  const pipelineRetryMutationHandler = jest
    .fn()
    .mockResolvedValue(mockRetryPipelineMutationResponse);
  const pipelineCancelMutationHandler = jest
    .fn()
    .mockResolvedValue(mockCancelPipelineMutationResponse);
  const pipelineRetryFailedMutationHandler = jest
    .fn()
    .mockResolvedValue(mockRetryFailedPipelineMutationResponse);
  const setSortPreferenceMutationSuccessHandler = jest
    .fn()
    .mockResolvedValue(setIdTypePreferenceMutationResponse);
  const setSortPreferenceMutationFailedHandler = jest
    .fn()
    .mockResolvedValue(setIdTypePreferenceMutationResponseWithErrors);

  const createMockApolloProvider = (
    requestHandlers = [
      [getPipelinesQuery, successHandler],
      [getAllPipelinesCountQuery, countHandler],
      [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
    ],
  ) => {
    return createMockApollo(requestHandlers);
  };

  const defaultProps = {
    params: {},
  };

  const createComponent = (props = {}, requestHandlers) => {
    wrapper = shallowMountExtended(Pipelines, {
      provide: {
        fullPath: 'gitlab-org/gitlab',
        newPipelinePath: '/gitlab-org/gitlab/-/pipelines/new',
        resetCachePath: '/gitlab-org/gitlab/-/settings/ci_cd/reset_cache',
        pipelinesAnalyticsPath: '/-/pipelines/charts',
        identityVerificationRequired: false,
        identityVerificationPath: '#',
      },
      stubs: {
        PipelinesTable,
      },
      propsData: { ...defaultProps, ...props },
      apolloProvider: createMockApolloProvider(requestHandlers),
    });
  };

  const findTable = () => wrapper.findComponent(PipelinesTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findNoCiEmptyState = () => wrapper.findComponent(NoCiEmptyState);
  const findTabs = () => wrapper.findComponent(NavigationTabs);
  const findNavControls = () => wrapper.findComponent(NavigationControls);
  const findFilteredSearch = () => wrapper.findComponent(PipelinesFilteredSearch);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPipelineKeyCollapsibleBox = () => wrapper.findComponent(GlCollapsibleListbox);

  const triggerNextPage = async () => {
    findPagination().vm.$emit('next');
    await waitForPromises();
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays table', async () => {
      await waitForPromises();

      expect(findTable().exists()).toBe(true);
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('displays filtered search', async () => {
      await waitForPromises();

      expect(findFilteredSearch().exists()).toBe(true);
    });

    it('handles loading state', async () => {
      expect(findLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('shows error empty state when there is an error', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, failedHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There was an error fetching the pipelines.');
    });

    it('shows tab empty state when not on the All tab', async () => {
      const dynamicHandler = jest.fn().mockImplementation((variables) => {
        if (variables.scope === 'TAGS' || variables.scope === 'FINISHED') {
          return Promise.resolve(mockPipelinesDataEmpty);
        }
        return Promise.resolve(mockPipelinesData);
      });

      createComponent(defaultProps, [
        [getPipelinesQuery, dynamicHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      findTabs().vm.$emit('onChangeTab', 'tags');

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There are currently no pipelines.');

      findTabs().vm.$emit('onChangeTab', 'finished');

      await waitForPromises();

      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There are currently no finished pipelines.');
    });

    it('shows no ci empty state when there are no pipelines', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, emptyHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      expect(findNoCiEmptyState().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('fetching pipelines', () => {
    it('fetches query correctly and passes pipelines to table', async () => {
      createComponent();

      expect(successHandler).toHaveBeenCalledWith({
        first: 15,
        fullPath: 'gitlab-org/gitlab',
        last: null,
        before: null,
        after: null,
        scope: null,
      });

      await waitForPromises();

      expect(findTable().props('pipelines')).toEqual(
        mockPipelinesData.data.project.pipelines.nodes,
      );
    });

    it('shows query error alert', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, failedHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while loading pipelines',
      });
    });
  });

  describe('tabs', () => {
    it('renders navigation tabs correctly', async () => {
      createComponent();

      await waitForPromises();

      expect(findTabs().exists()).toBe(true);
    });

    it('displays All tab pipeline count', async () => {
      createComponent();

      await waitForPromises();

      expect(findTabs().props('tabs')[0]).toStrictEqual({
        count: 2,
        isActive: true,
        name: 'All',
        scope: 'all',
      });
    });

    it.each`
      scope         | params
      ${'all'}      | ${{ scope: null }}
      ${'finished'} | ${{ scope: 'FINISHED' }}
      ${'branches'} | ${{ scope: 'BRANCHES' }}
      ${'tags'}     | ${{ scope: 'TAGS' }}
    `(
      'when the scope is $scope, then the query should be called with $params',
      async ({ scope, params }) => {
        createComponent();

        jest.spyOn(urlUtils, 'updateHistory');

        await waitForPromises();

        findTabs().vm.$emit('onChangeTab', scope);

        await waitForPromises();

        expect(successHandler).toHaveBeenCalledWith(expect.objectContaining(params));

        // inital load does not start with a scope
        if (params.scope) {
          expect(urlUtils.updateHistory).toHaveBeenCalledWith({
            url: `${TEST_HOST}/?scope=${scope}`,
          });
        }
      },
    );
  });

  describe('nav links', () => {
    it('renders navigation controls', async () => {
      createComponent();

      await waitForPromises();

      expect(findNavControls().exists()).toBe(true);
    });

    it('clears runner cache', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [clearRunnerCacheMutation, clearCacheMutationSuccessHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      findNavControls().vm.$emit('resetRunnersCache');

      expect(clearCacheMutationSuccessHandler).toHaveBeenCalledWith({
        input: {
          projectId: 'gid://gitlab/Project/19',
        },
      });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Project cache successfully reset.',
        variant: 'info',
      });
    });

    it('shows an error alert when clearing runner cache fails', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [clearRunnerCacheMutation, clearCacheMutationFailedHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      findNavControls().vm.$emit('resetRunnersCache');

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while cleaning runners cache.',
      });
    });
  });

  describe('pipelines filtered search', () => {
    it('passes intial params to filtered search', async () => {
      const expectedParams = {
        ref: 'test',
        scope: 'all',
        source: 'schedule',
        status: 'success',
        username: 'root',
      };

      createComponent({ params: expectedParams });

      await waitForPromises();

      expect(findFilteredSearch().props('params')).toEqual(expectedParams);
    });

    it('filters pipelines based on params', async () => {
      jest.spyOn(urlUtils, 'updateHistory');

      const expectedParams = {
        after: null,
        before: null,
        first: 15,
        fullPath: 'gitlab-org/gitlab',
        last: null,
        ref: 'test',
        scope: null,
        source: 'SCHEDULE',
        status: 'SUCCESS',
        username: 'root',
      };

      createComponent();

      await waitForPromises();

      findFilteredSearch().vm.$emit('filterPipelines', mockPipelinesFilteredSearch);

      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith(expectedParams);
      expect(urlUtils.updateHistory).toHaveBeenCalledWith({
        url: `${TEST_HOST}/?username=root&status=success&source=schedule&ref=test&scope=all`,
      });
    });

    it('displays a warning message if raw text search is used', async () => {
      createComponent();

      await waitForPromises();

      findFilteredSearch().vm.$emit('filterPipelines', ['rawText']);

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        message:
          'Raw text search is not currently supported. Please use the available search tokens.',
        variant: 'warning',
      });
    });
  });

  describe('changing pipeline ID type', () => {
    beforeEach(() => {
      gon.current_user_id = 1;

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    it('should change the text to Show Pipeline IID', async () => {
      createComponent();

      await waitForPromises();

      expect(findPipelineKeyCollapsibleBox().exists()).toBe(true);
      expect(findTable().props('pipelineIdType')).toBe('id');

      findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

      await waitForPromises();

      expect(findTable().props('pipelineIdType')).toBe('iid');
    });

    it('tracks the iid usage of the ID/IID dropdown', async () => {
      createComponent();

      await waitForPromises();

      findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

      await waitForPromises();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'pipelines_display_options', {
        label: TRACKING_CATEGORIES.listbox,
        property: 'iid',
      });
    });

    it('does not track the id usage of the ID/IID dropdown', async () => {
      createComponent();

      await waitForPromises();

      findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_ID_KEY);

      await waitForPromises();

      expect(trackingSpy).not.toHaveBeenCalled();
    });

    it('calls mutation to save idType preference', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [setSortPreferenceMutation, setSortPreferenceMutationSuccessHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

      await waitForPromises();

      expect(setSortPreferenceMutationSuccessHandler).toHaveBeenCalledWith({
        input: { visibilityPipelineIdType: PIPELINE_IID_KEY.toUpperCase() },
      });
    });

    it('captures error when mutation response has errors', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [setSortPreferenceMutation, setSortPreferenceMutationFailedHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
      ]);

      await waitForPromises();

      findPipelineKeyCollapsibleBox().vm.$emit('select', PIPELINE_IID_KEY);

      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalledWith(new Error('oh no!'));
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      createComponent();
    });

    it('handles pagination visibility while loading', async () => {
      expect(findPagination().exists()).toBe(false);

      await waitForPromises();

      expect(findPagination().exists()).toBe(true);
    });

    it('passes correct props to pagination', async () => {
      await waitForPromises();

      expect(findPagination().props()).toMatchObject({
        startCursor: 'eyJpZCI6IjcwMSJ9',
        endCursor: 'eyJpZCI6IjY3NSJ9',
        hasNextPage: true,
        hasPreviousPage: false,
      });
    });

    it('updates query variables when going to next page', async () => {
      await waitForPromises();

      await triggerNextPage();

      expect(successHandler).toHaveBeenCalledWith({
        fullPath: 'gitlab-org/gitlab',
        first: 15,
        last: null,
        before: null,
        after: 'eyJpZCI6IjY3NSJ9',
        scope: null,
      });
      expect(findPagination().props()).toMatchObject({});
    });
  });

  describe('events', () => {
    describe('successful events', () => {
      beforeEach(async () => {
        createComponent(defaultProps, [
          [getPipelinesQuery, successHandler],
          [retryPipelineMutation, pipelineRetryMutationHandler],
          [cancelPipelineMutation, pipelineCancelMutationHandler],
          [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
        ]);

        await waitForPromises();
      });

      it('retries the pipeline', async () => {
        const retriedPipeline = mockPipelinesData.data.project.pipelines.nodes[0];
        findTable().vm.$emit('retry-pipeline', retriedPipeline);

        await waitForPromises();

        expect(pipelineRetryMutationHandler).toHaveBeenCalledWith({ id: retriedPipeline.id });
      });

      it('cancels the pipeline', async () => {
        const canceledPipeline = mockPipelinesData.data.project.pipelines.nodes[0];
        findTable().vm.$emit('cancel-pipeline', canceledPipeline);

        await waitForPromises();

        expect(pipelineCancelMutationHandler).toHaveBeenCalledWith({ id: canceledPipeline.id });
      });
    });

    describe('errors during the mutations', () => {
      beforeEach(async () => {
        createComponent(defaultProps, [
          [getPipelinesQuery, successHandler],
          [getAllPipelinesCountQuery, countHandler],
          [retryPipelineMutation, pipelineRetryFailedMutationHandler],
          [ciPipelineStatusesUpdatedSubscription, subscriptionHandlerEmpty],
        ]);

        await waitForPromises();
      });

      it('displays an alert message when the mutation fails', async () => {
        const retriedPipeline = mockPipelinesData.data.project.pipelines.nodes[0];
        findTable().vm.$emit('retry-pipeline', retriedPipeline);

        await waitForPromises();

        expect(createAlert).toHaveBeenCalledWith({
          message: 'The pipeline could not be retried.',
        });
      });
    });
  });

  describe('subscription', () => {
    it('calls subscription with correct variables', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [getAllPipelinesCountQuery, countHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandler],
      ]);

      await waitForPromises();

      expect(subscriptionHandler).toHaveBeenCalledWith({ projectId: 'gid://gitlab/Project/19' });
    });

    it('passes updated pipeline from subscription to table', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, successHandler],
        [getAllPipelinesCountQuery, countHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandler],
      ]);

      await waitForPromises();

      expect(findTable().props('pipelines')[0].detailedStatus.icon).toBe('status_running');
    });

    it('skips subscription where there are no pipelines', async () => {
      createComponent(defaultProps, [
        [getPipelinesQuery, emptyHandler],
        [getAllPipelinesCountQuery, countHandler],
        [ciPipelineStatusesUpdatedSubscription, subscriptionHandler],
      ]);

      await waitForPromises();

      expect(subscriptionHandler).not.toHaveBeenCalled();
    });
  });
});

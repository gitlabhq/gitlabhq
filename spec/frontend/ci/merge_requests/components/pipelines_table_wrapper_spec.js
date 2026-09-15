import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLoadingIcon, GlModal, GlKeysetPagination } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import Api from '~/api';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { setupQueryPollingByVisibility } from '~/graphql_shared/utils';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';
import PipelinesErrorState from '~/ci/common/empty_state/pipelines_error_state.vue';
import PipelinesTableWrapper from '~/ci/merge_requests/components/pipelines_table_wrapper.vue';
import RunPipelineButton from '~/ci/common/run_pipeline_button.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  MR_PIPELINE_TYPE_DETACHED,
  MR_PIPELINE_TYPE_MERGED_RESULT,
  MR_PIPELINE_TYPE_MERGE_TRAIN,
} from '~/ci/merge_requests/constants';
import getMergeRequestsPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
import getPipelinesDownstream from '~/ci/merge_requests/graphql/queries/get_pipelines_downstream.query.graphql';
import getMergeRequestSinglePipeline from '~/ci/merge_requests/graphql/queries/get_merge_request_single_pipeline.query.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import mrPipelineStatusesUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/mr_pipeline_statuses_updated.subscription.graphql';
import downstreamPipelineStatusUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/downstream_pipeline_status_updated.subscription.graphql';
import getPipelineCreationRequests from '~/ci/merge_requests/graphql/queries/get_pipeline_creation_requests.query.graphql';
import pipelineCreationRequestsUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/pipeline_creation_requests_updated.subscription.graphql';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  generateMRPipelinesResponse,
  generateMockPipeline,
  generateMockDownstreamPipeline,
  generateSinglePipelineResponse,
  mockPipelineUpdateResponseEmpty,
  mockPipelineUpdateResponse,
  mockDownstreamPipelineUpdateResponse,
  generatePipelinesDownstreamResponse,
  generatePipelineCreationRequestsResponse,
  generatePipelineCreationSubscriptionResponse,
  generatePipelineCreationRequest,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/graphql_shared/utils', () => ({
  ...jest.requireActual('~/graphql_shared/utils'),
  setupQueryPollingByVisibility: jest.fn(),
}));

const $toast = {
  show: jest.fn(),
};

let wrapper;
let mergeRequestPipelinesRequest;
let pipelinesDownstreamRequest;
let getSinglePipelineRequest;
let cancelPipelineMutationRequest;
let retryPipelineMutationRequest;
let subscriptionHandler;
let downstreamSubscriptionHandler;
let mockDownstreamSubscription;
let pipelineCreationRequestsHandler;
let pipelineCreationSubscriptionHandler;
let mockPipelineCreationSubscription;
let apolloMock;
const showMock = jest.fn();

const defaultProvide = {
  newPipelinePath: '/group/project/-/pipelines/new',
};

const defaultProps = {
  canRunPipeline: true,
  projectId: '5',
  mergeRequestId: 1,
  targetProjectFullPath: '/group/project',
};

// Downstream is fetched separately from the connection query. This configures the separate
// downstream query's mock response for the given pipeline and returns the plain pipeline node
// (no inline downstream) for insertion into the connection query's mocked response.
const pipelineWithDownstream = (pipeline, downstreamNodes) => {
  pipelinesDownstreamRequest.mockResolvedValue(
    generatePipelinesDownstreamResponse([{ id: pipeline.id, downstreamNodes }]),
  );
  return pipeline;
};

const createResponseWithPageInfo = ({ hasNextPage, hasPreviousPage }) => {
  const response = generateMRPipelinesResponse({ count: 1 });
  response.data.project.mergeRequest.pipelines.pageInfo = {
    hasNextPage,
    hasPreviousPage,
    startCursor: hasPreviousPage ? 'eyJpZCI6IjcwMSJ9' : null,
    endCursor: hasPreviousPage ? 'eyJpZCI6IjY3NSJ9' : null,
    __typename: 'PageInfo',
  };
  return response;
};

const createComponent = ({ mountFn = shallowMountExtended, props = {}, stubs = {} } = {}) => {
  mockDownstreamSubscription = createMockSubscription();
  let isFirstDownstreamCall = true;
  downstreamSubscriptionHandler = jest.fn().mockImplementation(() => {
    if (isFirstDownstreamCall) {
      isFirstDownstreamCall = false;
      return mockDownstreamSubscription;
    }
    return createMockSubscription();
  });

  const handlers = [
    [getMergeRequestsPipelines, mergeRequestPipelinesRequest],
    [getPipelinesDownstream, pipelinesDownstreamRequest],
    [getMergeRequestSinglePipeline, getSinglePipelineRequest],
    [cancelPipelineMutation, cancelPipelineMutationRequest],
    [retryPipelineMutation, retryPipelineMutationRequest],
    [mrPipelineStatusesUpdatedSubscription, subscriptionHandler],
    [downstreamPipelineStatusUpdatedSubscription, downstreamSubscriptionHandler],
    [getPipelineCreationRequests, pipelineCreationRequestsHandler],
  ];

  apolloMock = createMockApollo(handlers);

  mockPipelineCreationSubscription = createMockSubscription();
  pipelineCreationSubscriptionHandler = jest.fn().mockReturnValue(mockPipelineCreationSubscription);
  apolloMock.defaultClient.setRequestHandler(
    pipelineCreationRequestsUpdatedSubscription,
    pipelineCreationSubscriptionHandler,
  );

  wrapper = mountFn(PipelinesTableWrapper, {
    apolloProvider: apolloMock,
    provide: {
      ...defaultProvide,
    },
    propsData: {
      ...defaultProps,
      ...props,
    },
    mocks: {
      $toast,
    },
    stubs: {
      GlModal: stubComponent(GlModal, {
        template: '<div />',
        methods: { show: showMock },
      }),
      ...stubs,
    },
  });

  return waitForPromises();
};

const findEmptyState = () => wrapper.findComponent(PipelinesEmptyState);
const findErrorEmptyState = () => wrapper.findComponent(PipelinesErrorState);
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findModal = () => wrapper.findComponent(GlModal);
const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');
const findPipelinesList = () => wrapper.findComponent(PipelinesTable);
const findRunPipelineBtn = () => wrapper.findComponent(RunPipelineButton);
const findCreationFailedAlert = () => wrapper.findComponent(GlAlert);
const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');
const findPagination = () => wrapper.findComponent(GlKeysetPagination);
const displayedPipelines = () => findPipelinesList().props('pipelines');

beforeEach(() => {
  mergeRequestPipelinesRequest = jest.fn();
  mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 1 }));

  pipelinesDownstreamRequest = jest.fn();
  pipelinesDownstreamRequest.mockResolvedValue(generatePipelinesDownstreamResponse([]));

  getSinglePipelineRequest = jest.fn();
  getSinglePipelineRequest.mockResolvedValue(
    generateSinglePipelineResponse(generateMockPipeline({ id: '1' })),
  );

  cancelPipelineMutationRequest = jest.fn();
  cancelPipelineMutationRequest.mockResolvedValue({ data: { pipelineCancel: { errors: [] } } });

  retryPipelineMutationRequest = jest.fn();
  retryPipelineMutationRequest.mockResolvedValue({ data: { pipelineRetry: { errors: [] } } });

  subscriptionHandler = jest.fn().mockResolvedValue(mockPipelineUpdateResponseEmpty);

  pipelineCreationRequestsHandler = jest
    .fn()
    .mockResolvedValue(generatePipelineCreationRequestsResponse({ requests: [] }));
});

afterEach(() => {
  apolloMock = null;
});

describe('PipelinesTableWrapper component', () => {
  describe('When queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render the pipeline list', () => {
      expect(findPipelinesList().exists()).toBe(false);
    });

    it('does not render pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('When there is an error fetching pipelines', () => {
    beforeEach(async () => {
      mergeRequestPipelinesRequest.mockRejectedValueOnce({ error: 'API error message' });
      await createComponent({ mountFn: mountExtended });
    });

    it('should render error state', () => {
      expect(findErrorEmptyState().exists()).toBe(true);
    });

    it('does not render pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('When queries have loaded', () => {
    it('does not render the loading icon', async () => {
      await createComponent();

      expect(findLoadingIcon().exists()).toBe(false);
    });

    describe('with pipelines', () => {
      beforeEach(async () => {
        await createComponent();
      });

      it('renders a pipeline list', () => {
        expect(findPipelinesList().exists()).toBe(true);
        expect(displayedPipelines()).toHaveLength(1);
      });

      it('renders pagination', () => {
        expect(findPagination().exists()).toBe(true);
      });
    });

    describe('without pipelines', () => {
      beforeEach(async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 0 }));
        await createComponent({ mountFn: mountExtended });
      });

      it('should render the empty state', () => {
        expect(findTableRows()).toHaveLength(0);
        expect(findErrorEmptyState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should render correct empty state content', () => {
        expect(findRunPipelineBtn().props()).toMatchObject({ isLoading: false, mergeRequestId: 1 });
        expect(findMrPipelinesDocsLink().attributes('href')).toBe(
          '/help/ci/pipelines/merge_request_pipelines.md#prerequisites',
        );
        expect(findUserPermissionsDocsLink().attributes('href')).toBe(
          '/help/user/permissions.md#project-cicd',
        );

        expect(findEmptyState().text()).toContain('To run a merge request pipeline');
      });

      it('does not render pagination', () => {
        expect(findPagination().exists()).toBe(false);
      });
    });

    describe('pipeline badge counts', () => {
      it('should receive update-pipelines-count event', () => {
        const element = document.createElement('div');
        document.body.appendChild(element);

        return new Promise((resolve) => {
          element.addEventListener('update-pipelines-count', (event) => {
            expect(event.detail.pipelineCount).toEqual(1);
            resolve();
          });

          createComponent();

          element.appendChild(wrapper.vm.$el);
        });
      });
    });
  });

  describe.each`
    eventType                         | description
    ${MR_PIPELINE_TYPE_DETACHED}      | ${'detached merge request pipeline'}
    ${MR_PIPELINE_TYPE_MERGED_RESULT} | ${'merged-results pipeline'}
    ${MR_PIPELINE_TYPE_MERGE_TRAIN}   | ${'merge train pipeline'}
  `('when latest pipeline is a $description', ({ eventType }) => {
    beforeEach(async () => {
      const response = generateMRPipelinesResponse({
        mergeRequestEventType: eventType,
      });

      mergeRequestPipelinesRequest.mockResolvedValue(response);

      await createComponent();
    });

    it('renders the run pipeline button', () => {
      expect(findRunPipelineBtn().props()).toMatchObject({ isLoading: false, mergeRequestId: 1 });
    });
  });

  describe('when latest pipeline is a branch pipeline', () => {
    beforeEach(async () => {
      mergeRequestPipelinesRequest.mockResolvedValue(
        generateMRPipelinesResponse({ mergeRequestEventType: null }),
      );

      await createComponent();
    });

    it('does not render the run pipeline button', () => {
      expect(findRunPipelineBtn().exists()).toBe(false);
    });
  });

  describe('run pipeline button', () => {
    describe('on click', () => {
      beforeEach(() => {
        const response = generateMRPipelinesResponse({
          mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
        });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
      });

      describe('failure', () => {
        const permissionsMsg = 'You do not have permission to run a pipeline on this branch.';
        const defaultMsg =
          'An error occurred while trying to run a new pipeline for this merge request.';

        it.each`
          status                               | message
          ${HTTP_STATUS_BAD_REQUEST}           | ${defaultMsg}
          ${HTTP_STATUS_UNAUTHORIZED}          | ${permissionsMsg}
          ${HTTP_STATUS_INTERNAL_SERVER_ERROR} | ${defaultMsg}
        `('displays permissions error message', async ({ status, message }) => {
          const response = { response: { status } };
          jest.spyOn(Api, 'postMergeRequestPipeline').mockRejectedValue(response);
          await createComponent({ mountFn: mountExtended });

          await findRunPipelineBtn().vm.$emit('run-pipeline');

          await waitForPromises();

          expect(createAlert).toHaveBeenCalledWith({
            message,
            primaryButton: {
              text: 'Learn more',
              link: '/help/ci/pipelines/merge_request_pipelines.md',
            },
          });
        });
      });

      it('shows loading immediately on click, before the POST resolves', async () => {
        let resolvePost;
        jest.spyOn(Api, 'postMergeRequestPipeline').mockReturnValue(
          new Promise((resolve) => {
            resolvePost = resolve;
          }),
        );
        await createComponent();

        findRunPipelineBtn().vm.$emit('run-pipeline');
        await nextTick();

        expect(findRunPipelineBtn().props('isLoading')).toBe(true);

        resolvePost();
        await waitForPromises();

        expect(findRunPipelineBtn().props('isLoading')).toBe(false);
      });

      it('does not send a second request while one is already in flight', async () => {
        const postSpy = jest
          .spyOn(Api, 'postMergeRequestPipeline')
          .mockReturnValue(new Promise(() => {}));
        await createComponent();

        findRunPipelineBtn().vm.$emit('run-pipeline');
        findRunPipelineBtn().vm.$emit('run-pipeline');
        await nextTick();

        expect(postSpy).toHaveBeenCalledTimes(1);
      });

      it('resets loading state when the POST rejects with a non-HTTP error', async () => {
        jest.spyOn(Api, 'postMergeRequestPipeline').mockRejectedValue(new Error('network down'));
        await createComponent();

        await findRunPipelineBtn().vm.$emit('run-pipeline');
        await waitForPromises();

        expect(findRunPipelineBtn().props('isLoading')).toBe(false);
      });
    });

    describe('on click for fork merge request', () => {
      beforeEach(async () => {
        const response = generateMRPipelinesResponse({
          mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
        });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent({
          props: {
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });

        jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();
      });

      it('shows a security warning modal', async () => {
        await findRunPipelineBtn().vm.$emit('run-pipeline');

        expect(showMock).toHaveBeenCalled();
        expect(findRunPipelineBtn().props('isLoading')).toBe(false);
      });
    });

    describe('on click for fork merge request when the latest pipeline ran in the target project', () => {
      beforeEach(async () => {
        const response = generateMRPipelinesResponse({
          mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
        });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent({
          props: {
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/fork-project',
            targetProjectFullPath: 'gitlab-org/gitlab',
          },
        });

        jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();
      });

      it('runs the pipeline without showing the security warning modal', async () => {
        await findRunPipelineBtn().vm.$emit('run-pipeline');

        expect(showMock).not.toHaveBeenCalled();
        expect(Api.postMergeRequestPipeline).toHaveBeenCalledWith('5', { mergeRequestId: 1 });
      });
    });

    describe('when no pipelines were created on a forked merge request', () => {
      beforeEach(async () => {
        const response = generateMRPipelinesResponse({ count: 0 });
        mergeRequestPipelinesRequest.mockResolvedValue(response);

        await createComponent({
          mountFn: mountExtended,
          props: {
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });
      });

      it('should show security modal from empty state run pipeline button', async () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findModal().exists()).toBe(true);

        await findRunPipelineBtn().vm.$emit('run-pipeline');

        expect(showMock).toHaveBeenCalled();
      });
    });

    describe('events', () => {
      beforeEach(async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse());
        await createComponent();
      });

      describe('When cancelling a pipeline', () => {
        it('execute the cancel graphql mutation', async () => {
          expect(cancelPipelineMutationRequest.mock.calls).toHaveLength(0);

          findPipelinesList().vm.$emit('cancel-pipeline', displayedPipelines()[0]);

          await waitForPromises();

          expect(cancelPipelineMutationRequest.mock.calls[0]).toEqual([
            { id: 'gid://gitlab/Ci::Pipeline/1' },
          ]);
        });

        it('refetches the single pipeline after successful cancel', async () => {
          expect(getSinglePipelineRequest).not.toHaveBeenCalled();

          findPipelinesList().vm.$emit('cancel-pipeline', displayedPipelines()[0]);

          await waitForPromises();

          expect(getSinglePipelineRequest).toHaveBeenCalledWith({
            fullPath: '/group/project',
            id: 'gid://gitlab/Ci::Pipeline/1',
          });
        });
      });

      describe('When retrying a pipeline', () => {
        it('sends the retry action graphql mutation', async () => {
          expect(retryPipelineMutationRequest.mock.calls).toHaveLength(0);

          findPipelinesList().vm.$emit('retry-pipeline', displayedPipelines()[0]);

          await waitForPromises();

          expect(retryPipelineMutationRequest.mock.calls[0]).toEqual([
            { id: 'gid://gitlab/Ci::Pipeline/1' },
          ]);
        });

        it('refetches the single pipeline after successful retry', async () => {
          expect(getSinglePipelineRequest).not.toHaveBeenCalled();

          findPipelinesList().vm.$emit('retry-pipeline', displayedPipelines()[0]);

          await waitForPromises();

          expect(getSinglePipelineRequest).toHaveBeenCalledWith({
            fullPath: '/group/project',
            id: 'gid://gitlab/Ci::Pipeline/1',
          });
        });
      });

      describe('When a job action is executed', () => {
        it('refetches the single pipeline', async () => {
          expect(getSinglePipelineRequest).not.toHaveBeenCalled();

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);

          await waitForPromises();

          expect(getSinglePipelineRequest).toHaveBeenCalledWith({
            fullPath: '/group/project',
            id: 'gid://gitlab/Ci::Pipeline/1',
          });
        });

        it('updates the pipeline in the list with refetched data', async () => {
          const updatedPipeline = generateMockPipeline({ id: '1', status: 'RUNNING' });
          getSinglePipelineRequest.mockResolvedValue(
            generateSinglePipelineResponse(updatedPipeline),
          );

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);

          await waitForPromises();

          expect(displayedPipelines()[0].detailedStatus.name).toBe('RUNNING');
        });

        it('updates a running pipeline to canceled status after cancel action', async () => {
          const runningResponse = generateMRPipelinesResponse({ count: 1, status: 'RUNNING' });
          mergeRequestPipelinesRequest.mockResolvedValue(runningResponse);
          await createComponent();

          expect(displayedPipelines()[0].detailedStatus.name).toBe('RUNNING');

          const canceledPipeline = generateMockPipeline({ id: '1', status: 'CANCELED' });
          getSinglePipelineRequest.mockResolvedValue(
            generateSinglePipelineResponse(canceledPipeline),
          );

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);

          await waitForPromises();

          expect(displayedPipelines()[0].detailedStatus.name).toBe('CANCELED');
        });

        it('keeps the same pipeline row after refetch', async () => {
          const updatedPipeline = generateMockPipeline({ id: '1', status: 'RUNNING' });
          getSinglePipelineRequest.mockResolvedValue(
            generateSinglePipelineResponse(updatedPipeline),
          );

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);

          await waitForPromises();

          expect(displayedPipelines()).toHaveLength(1);
          expect(displayedPipelines()[0].id).toBe('gid://gitlab/Ci::Pipeline/1');
        });

        it('preserves the cached downstream after a base-only single-pipeline refetch', async () => {
          const downstream = generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' });
          mergeRequestPipelinesRequest.mockResolvedValue(
            (() => {
              const response = generateMRPipelinesResponse({ count: 1, status: 'RUNNING' });
              response.data.project.mergeRequest.pipelines.nodes = [
                pipelineWithDownstream(generateMockPipeline({ id: '1', status: 'RUNNING' }), [
                  downstream,
                ]),
              ];
              return response;
            })(),
          );
          await createComponent();

          expect(displayedPipelines()[0].downstream.nodes).toHaveLength(1);

          // The single-pipeline query does not select downstream; the refetch must not wipe it.
          getSinglePipelineRequest.mockResolvedValue(
            generateSinglePipelineResponse(generateMockPipeline({ id: '1', status: 'SUCCESS' })),
          );
          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);
          await waitForPromises();

          expect(displayedPipelines()[0].detailedStatus.name).toBe('SUCCESS');
          expect(displayedPipelines()[0].downstream.nodes).toHaveLength(1);
        });

        it('refetches downstream pipelines, since a job action can create a new one', async () => {
          expect(pipelinesDownstreamRequest).toHaveBeenCalledTimes(1);

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);
          await waitForPromises();

          expect(pipelinesDownstreamRequest).toHaveBeenCalledTimes(2);
        });

        it('captures Sentry error on refetch failure', async () => {
          getSinglePipelineRequest.mockRejectedValueOnce(new Error('network error'));

          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);

          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(expect.any(Error));
        });
      });

      describe('when a manual job is played via pipeline actions dropdown', () => {
        beforeEach(() => {
          // simulate PipelinesManualActions → PipelineOperations → PipelinesTable
          findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);
          return waitForPromises();
        });

        it('refetches the single pipeline', () => {
          expect(getSinglePipelineRequest).toHaveBeenCalledWith({
            fullPath: defaultProps.targetProjectFullPath,
            id: 'gid://gitlab/Ci::Pipeline/1',
          });
        });

        it('does not reset pagination', () => {
          // refetchSinglePipeline does not re-run the connection query
          expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1); // only initial load
        });
      });
    });
  });

  describe('polling', () => {
    const POLL_INTERVAL_MS = 60 * 1000;

    it('sets a poll interval on the pipelines queries', async () => {
      await createComponent();
      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);
      expect(pipelinesDownstreamRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(POLL_INTERVAL_MS + 1);
      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(2);
      expect(pipelinesDownstreamRequest).toHaveBeenCalledTimes(2);
    });

    it('sets up visibility-based polling for the pipelines and downstreamPipelines queries', async () => {
      await createComponent();

      expect(setupQueryPollingByVisibility).toHaveBeenCalledTimes(2);
      expect(setupQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.pipelines,
        POLL_INTERVAL_MS,
      );
      expect(setupQueryPollingByVisibility).toHaveBeenCalledWith(
        wrapper.vm.$apollo.queries.downstreamPipelines,
        POLL_INTERVAL_MS,
      );
    });

    it('cleans up visibility listeners on unmount', async () => {
      const pipelinesCleanup = jest.fn();
      const downstreamCleanup = jest.fn();
      setupQueryPollingByVisibility
        .mockReturnValueOnce(pipelinesCleanup)
        .mockReturnValueOnce(downstreamCleanup);

      await createComponent();
      wrapper.destroy();

      expect(pipelinesCleanup).toHaveBeenCalled();
      expect(downstreamCleanup).toHaveBeenCalled();
    });
  });

  describe('pagination', () => {
    it.each`
      scenario                                                                 | hasNextPage | hasPreviousPage
      ${'does not render pagination when there are no next or previous pages'} | ${false}    | ${false}
      ${'renders pagination when hasNextPage is true'}                         | ${true}     | ${false}
      ${'renders pagination when hasPreviousPage is true'}                     | ${false}    | ${true}
    `('$scenario', async ({ hasNextPage, hasPreviousPage }) => {
      const response = createResponseWithPageInfo({ hasNextPage, hasPreviousPage });
      mergeRequestPipelinesRequest.mockResolvedValue(response);

      await createComponent();

      expect(findPagination().exists()).toBe(hasNextPage || hasPreviousPage);
    });

    it('passes correct pageInfo props to pagination', async () => {
      await createComponent();

      expect(findPagination().props()).toMatchObject({
        startCursor: 'eyJpZCI6IjcwMSJ9',
        endCursor: 'eyJpZCI6IjY3NSJ9',
        hasNextPage: true,
        hasPreviousPage: false,
      });
    });

    describe('next page', () => {
      it('updates query variables with correct pagination params when clicking next', async () => {
        await createComponent();

        findPagination().vm.$emit('next');

        await waitForPromises();

        expect(mergeRequestPipelinesRequest).toHaveBeenCalledWith({
          first: 15,
          last: null,
          after: 'eyJpZCI6IjY3NSJ9',
          before: '',
          fullPath: '/group/project',
          mergeRequestIid: '1',
        });
      });
    });

    describe('previous page', () => {
      it('updates query variables with correct pagination params when clicking prev', async () => {
        const responseWithPreviousPage = createResponseWithPageInfo({
          hasNextPage: false,
          hasPreviousPage: true,
        });
        mergeRequestPipelinesRequest.mockResolvedValue(responseWithPreviousPage);

        await createComponent();

        findPagination().vm.$emit('prev');

        await waitForPromises();

        expect(mergeRequestPipelinesRequest).toHaveBeenCalledWith({
          first: null,
          last: 15,
          after: '',
          before: 'eyJpZCI6IjcwMSJ9',
          fullPath: '/group/project',
          mergeRequestIid: '1',
        });
      });
    });
  });

  describe('subscription', () => {
    describe('subscribing to active pipelines', () => {
      it('subscribes to each active pipeline with correct pipeline ID', async () => {
        const response = generateMRPipelinesResponse({ count: 1, status: 'RUNNING' });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
        await createComponent();

        expect(subscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/1',
        });
      });

      it('does not subscribe to completed pipelines', async () => {
        const response = generateMRPipelinesResponse({ count: 1, status: 'SUCCESS' });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
        await createComponent();

        expect(subscriptionHandler).not.toHaveBeenCalled();
      });

      it('subscribes only to running pipelines when mixed statuses exist', async () => {
        const response = generateMRPipelinesResponse({ count: 0 });
        response.data.project.mergeRequest.pipelines.nodes = [
          generateMockPipeline({ id: '1', status: 'RUNNING' }),
          generateMockPipeline({ id: '2', status: 'SUCCESS' }),
          generateMockPipeline({ id: '3', status: 'PENDING' }),
          generateMockPipeline({ id: '4', status: 'FAILED' }),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
        await createComponent();

        expect(subscriptionHandler).toHaveBeenCalledTimes(2);
        expect(subscriptionHandler).toHaveBeenNthCalledWith(1, {
          pipelineId: 'gid://gitlab/Ci::Pipeline/1',
        });
        expect(subscriptionHandler).toHaveBeenNthCalledWith(2, {
          pipelineId: 'gid://gitlab/Ci::Pipeline/3',
        });
      });

      it.each`
        status                    | shouldSubscribe
        ${'CREATED'}              | ${true}
        ${'WAITING_FOR_RESOURCE'} | ${true}
        ${'PREPARING'}            | ${true}
        ${'WAITING_FOR_CALLBACK'} | ${true}
        ${'PENDING'}              | ${true}
        ${'RUNNING'}              | ${true}
        ${'CANCELING'}            | ${true}
        ${'SUCCESS'}              | ${false}
        ${'FAILED'}               | ${false}
        ${'CANCELED'}             | ${false}
        ${'SKIPPED'}              | ${false}
        ${'MANUAL'}               | ${false}
      `(
        'subscribes to pipeline with status $status: $shouldSubscribe',
        async ({ status, shouldSubscribe }) => {
          const response = generateMRPipelinesResponse({ count: 0 });
          response.data.project.mergeRequest.pipelines.nodes = [
            generateMockPipeline({ id: '1', status }),
          ];
          mergeRequestPipelinesRequest.mockResolvedValue(response);
          subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
          await createComponent();

          if (shouldSubscribe) {
            expect(subscriptionHandler).toHaveBeenCalledWith({
              pipelineId: 'gid://gitlab/Ci::Pipeline/1',
            });
          } else {
            expect(subscriptionHandler).not.toHaveBeenCalled();
          }
        },
      );

      it('applies the subscription status update to the rendered row', async () => {
        const mockSub = createMockSubscription();
        subscriptionHandler = jest.fn().mockReturnValue(mockSub);

        const response = generateMRPipelinesResponse({ count: 0 });
        response.data.project.mergeRequest.pipelines.nodes = [
          generateMockPipeline({ id: '701', status: 'RUNNING' }),
        ];

        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();

        expect(displayedPipelines()[0].stages.nodes.map((s) => s.detailedStatus.name)).toEqual([
          'SUCCESS',
          'SUCCESS',
          'SUCCESS',
        ]);

        mockSub.next(mockPipelineUpdateResponse);
        await waitForPromises();

        const updatedStages = displayedPipelines()[0].stages.nodes;

        expect(updatedStages.map((s) => s.detailedStatus.name)).toEqual([
          'RUNNING',
          'CREATED',
          'CREATED',
        ]);
        expect(updatedStages.map((s) => s.detailedStatus.icon)).toEqual([
          'status_running',
          'status_created',
          'status_created',
        ]);
      });

      it('skips subscription when there are no pipelines', async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 0 }));
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
        await createComponent();

        expect(subscriptionHandler).not.toHaveBeenCalled();
      });
    });

    describe('subscription lifecycle driven by user actions and ticks', () => {
      const buildTick = (status) => ({
        data: {
          ciPipelineStatusUpdated: {
            ...mockPipelineUpdateResponse.data.ciPipelineStatusUpdated,
            detailedStatus: {
              ...mockPipelineUpdateResponse.data.ciPipelineStatusUpdated.detailedStatus,
              name: status,
              icon: `status_${status.toLowerCase()}`,
            },
          },
        },
      });

      it('subscribes to a terminal parent pipeline after retry', async () => {
        const response = generateMRPipelinesResponse({ count: 1, status: 'SUCCESS' });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();

        expect(subscriptionHandler).not.toHaveBeenCalled();

        findPipelinesList().vm.$emit('retry-pipeline', displayedPipelines()[0]);
        await waitForPromises();

        expect(subscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/1',
        });
      });

      it('subscribes to a terminal parent pipeline after a job action on it', async () => {
        const response = generateMRPipelinesResponse({ count: 1, status: 'FAILED' });
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();

        expect(subscriptionHandler).not.toHaveBeenCalled();

        findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);
        await waitForPromises();

        expect(subscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/1',
        });
      });

      it('subscribes to a terminal downstream after a job action on its parent', async () => {
        const downstream = generateMockDownstreamPipeline({ id: '100', status: 'SUCCESS' });
        const response = generateMRPipelinesResponse({ count: 0 });
        response.data.project.mergeRequest.pipelines.nodes = [
          pipelineWithDownstream(generateMockPipeline({ id: '1', status: 'RUNNING' }), [
            downstream,
          ]),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();

        expect(downstreamSubscriptionHandler).not.toHaveBeenCalled();

        findPipelinesList().vm.$emit('job-action-executed', displayedPipelines()[0]);
        await waitForPromises();

        expect(downstreamSubscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/100',
        });
      });

      it('stops applying ticks for a parent once a terminal status is reported', async () => {
        const mockParentSub = createMockSubscription();
        subscriptionHandler = jest.fn().mockReturnValue(mockParentSub);

        const response = generateMRPipelinesResponse({ count: 0 });
        response.data.project.mergeRequest.pipelines.nodes = [
          generateMockPipeline({ id: '701', status: 'RUNNING' }),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();

        expect(displayedPipelines()[0].detailedStatus.name).toBe('RUNNING');

        mockParentSub.next(buildTick('SUCCESS'));
        await waitForPromises();

        expect(displayedPipelines()[0].detailedStatus.name).toBe('SUCCESS');

        // Subscription is torn down; second tick should be ignored
        const statusBeforeSecondTick = displayedPipelines()[0].detailedStatus.name;
        mockParentSub.next(buildTick('RUNNING'));
        await waitForPromises();

        expect(displayedPipelines()[0].detailedStatus.name).toBe(statusBeforeSecondTick);
      });
    });

    describe('downstream pipeline subscriptions', () => {
      const createWithDownstream = async (
        downstreamPipelines,
        { parentStatus = 'RUNNING' } = {},
      ) => {
        const response = generateMRPipelinesResponse({ count: 0 });
        response.data.project.mergeRequest.pipelines.nodes = [
          pipelineWithDownstream(
            generateMockPipeline({ id: '1', status: parentStatus }),
            downstreamPipelines,
          ),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponseEmpty);
        await createComponent();
      };

      it('subscribes to each alive downstream pipeline', async () => {
        const downstream = generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' });
        await createWithDownstream([downstream]);

        expect(downstreamSubscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/100',
        });
      });

      it('does not subscribe to completed downstream pipelines', async () => {
        const downstream = generateMockDownstreamPipeline({ id: '100', status: 'SUCCESS' });
        await createWithDownstream([downstream]);

        expect(downstreamSubscriptionHandler).not.toHaveBeenCalled();
      });

      it('subscribes only to alive downstream pipelines when mixed statuses exist', async () => {
        await createWithDownstream([
          generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' }),
          generateMockDownstreamPipeline({ id: '101', status: 'SUCCESS' }),
          generateMockDownstreamPipeline({ id: '102', status: 'PENDING' }),
        ]);

        expect(downstreamSubscriptionHandler).toHaveBeenCalledTimes(2);
        expect(downstreamSubscriptionHandler).toHaveBeenNthCalledWith(1, {
          pipelineId: 'gid://gitlab/Ci::Pipeline/100',
        });
        expect(downstreamSubscriptionHandler).toHaveBeenNthCalledWith(2, {
          pipelineId: 'gid://gitlab/Ci::Pipeline/102',
        });
      });

      it('subscribes to alive downstream pipelines even when parent is completed', async () => {
        const downstream = generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' });
        await createWithDownstream([downstream], { parentStatus: 'SUCCESS' });

        expect(downstreamSubscriptionHandler).toHaveBeenCalledWith({
          pipelineId: 'gid://gitlab/Ci::Pipeline/100',
        });
      });

      it('updates downstream pipeline status when subscription receives data', async () => {
        const downstream = generateMockDownstreamPipeline({ id: '100', status: 'RUNNING' });
        await createWithDownstream([downstream]);

        expect(displayedPipelines()[0].downstream.nodes[0].detailedStatus.name).toBe('RUNNING');

        mockDownstreamSubscription.next(mockDownstreamPipelineUpdateResponse);
        await waitForPromises();

        expect(displayedPipelines()[0].downstream.nodes[0].detailedStatus.name).toBe('SUCCESS');
      });
    });
  });

  describe('pipeline creation requests', () => {
    useLocalStorageSpy();

    const dismissedAlertsStorageKey = 'mr_pipelines_dismissed_creation_alerts_/group/project_1';
    const inProgressRequest = generatePipelineCreationRequest({
      status: 'IN_PROGRESS',
      pipelineId: null,
      pipeline: null,
    });
    const failedRequest = generatePipelineCreationRequest({
      id: 'failed-request-uuid',
      status: 'FAILED',
      pipelineId: null,
      pipeline: null,
      error: 'Creation failed',
    });
    const automaticFailedRequest = generatePipelineCreationRequest({
      id: 'automatic-request-uuid',
      status: 'FAILED',
      pipelineId: null,
      pipeline: null,
      error: 'Creation failed',
      userInitiated: false,
    });
    const succeededRequest = generatePipelineCreationRequest({
      status: 'SUCCEEDED',
      pipelineId: 'gid://gitlab/Ci::Pipeline/999',
    });

    const setupPipelineCreationRequestsResponse = (requests) => {
      pipelineCreationRequestsHandler.mockResolvedValue(
        generatePipelineCreationRequestsResponse({ requests }),
      );
    };

    const emitSubscriptionUpdate = (requests) => {
      mockPipelineCreationSubscription.next(
        generatePipelineCreationSubscriptionResponse({ requests }),
      );
    };

    const setupDetachedPipelineResponse = () => {
      mergeRequestPipelinesRequest.mockResolvedValue(
        generateMRPipelinesResponse({ mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED }),
      );
    };

    describe('query', () => {
      it('calls with correct variables', async () => {
        await createComponent();

        expect(pipelineCreationRequestsHandler).toHaveBeenCalledWith({
          fullPath: '/group/project',
          mergeRequestIid: '1',
        });
      });
    });

    describe('subscription', () => {
      it('subscribes with correct mergeRequestId', async () => {
        await createComponent();

        expect(pipelineCreationSubscriptionHandler).toHaveBeenCalledWith({
          mergeRequestId: 'gid://gitlab/MergeRequest/1',
        });
      });

      it('skips when mergeRequestGid is not available', async () => {
        pipelineCreationRequestsHandler.mockResolvedValue({
          data: {
            project: {
              __typename: 'Project',
              id: 'gid://gitlab/Project/1',
              fullPath: 'root/project-1',
              mergeRequest: null,
            },
          },
        });

        await createComponent();

        expect(pipelineCreationSubscriptionHandler).not.toHaveBeenCalled();
      });
    });

    describe('optimistic new pipelines', () => {
      it('shows a SUCCEEDED creation-request pipeline the server list has not returned yet', async () => {
        setupPipelineCreationRequestsResponse([succeededRequest]);

        await createComponent();

        const pipelines = displayedPipelines();
        expect(pipelines).toHaveLength(2);
        expect(pipelines[0].id).toBe('gid://gitlab/Ci::Pipeline/999');
      });

      it('does not duplicate the pipeline once the server list includes it', async () => {
        setupPipelineCreationRequestsResponse([succeededRequest]);

        const responseWithNewPipeline = generateMRPipelinesResponse({ count: 2 });
        responseWithNewPipeline.data.project.mergeRequest.pipelines.nodes = [
          generateMockPipeline({ id: '999', status: 'RUNNING' }),
          generateMockPipeline({ id: '1', status: 'SUCCESS' }),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(responseWithNewPipeline);

        await createComponent();

        const pipelineIds = displayedPipelines().map((p) => p.id);
        expect(pipelineIds).toHaveLength(2);
        expect(pipelineIds.filter((id) => id === 'gid://gitlab/Ci::Pipeline/999')).toHaveLength(1);
      });
    });

    describe('initial state from query', () => {
      describe('failed alert', () => {
        it('shows alert when pipeline creation fails', async () => {
          setupPipelineCreationRequestsResponse([failedRequest]);

          await createComponent();

          expect(findCreationFailedAlert().text()).toBe(
            'Pipeline creation failed. Please try again.',
          );
          expect(findCreationFailedAlert().props('variant')).toBe('danger');
        });

        it('hides alert when dismissed', async () => {
          setupPipelineCreationRequestsResponse([failedRequest]);

          await createComponent();

          expect(findCreationFailedAlert().exists()).toBe(true);

          await findCreationFailedAlert().vm.$emit('dismiss');

          expect(findCreationFailedAlert().exists()).toBe(false);
        });

        it('does not show alert for an automatic failed request', async () => {
          setupPipelineCreationRequestsResponse([automaticFailedRequest]);

          await createComponent();

          expect(findCreationFailedAlert().exists()).toBe(false);
        });

        it('persists dismissed request ids to localStorage', async () => {
          setupPipelineCreationRequestsResponse([failedRequest]);

          await createComponent({ stubs: { LocalStorageSync } });
          await findCreationFailedAlert().vm.$emit('dismiss');

          expect(localStorage.setItem).toHaveBeenCalledWith(
            dismissedAlertsStorageKey,
            JSON.stringify(['failed-request-uuid']),
          );
        });

        it('does not show alert when the failed request was already dismissed', async () => {
          localStorage.setItem(dismissedAlertsStorageKey, JSON.stringify(['failed-request-uuid']));
          setupPipelineCreationRequestsResponse([failedRequest]);

          await createComponent({ stubs: { LocalStorageSync } });

          expect(findCreationFailedAlert().exists()).toBe(false);
        });

        it('shows alert for a failed request without an id but does not persist its dismissal', async () => {
          const nullIdFailedRequest = generatePipelineCreationRequest({
            id: null,
            status: 'FAILED',
            pipelineId: null,
            pipeline: null,
            error: 'Creation failed',
          });
          setupPipelineCreationRequestsResponse([nullIdFailedRequest]);

          await createComponent({ stubs: { LocalStorageSync } });

          expect(findCreationFailedAlert().exists()).toBe(true);

          localStorage.setItem.mockClear();
          await findCreationFailedAlert().vm.$emit('dismiss');

          expect(findCreationFailedAlert().exists()).toBe(false);
          expect(localStorage.setItem).not.toHaveBeenCalled();
        });
      });

      describe('run pipeline button', () => {
        beforeEach(() => {
          setupDetachedPipelineResponse();
        });

        it('shows loading state when IN_PROGRESS requests exist', async () => {
          setupPipelineCreationRequestsResponse([inProgressRequest]);

          await createComponent();

          expect(findRunPipelineBtn().props('isLoading')).toBe(true);
        });

        it('does not show toast when running pipeline', async () => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();

          await createComponent();

          await findRunPipelineBtn().vm.$emit('run-pipeline');
          await waitForPromises();

          expect($toast.show).not.toHaveBeenCalled();
        });
      });
    });

    it('clears debounce timeout on component unmount', async () => {
      setupDetachedPipelineResponse();
      jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();

      await createComponent();

      const clearTimeoutSpy = jest.spyOn(global, 'clearTimeout');

      await findRunPipelineBtn().vm.$emit('run-pipeline');

      wrapper.destroy();

      expect(clearTimeoutSpy).toHaveBeenCalled();
    });

    describe('subscription updates', () => {
      it('prepends new pipeline to list on SUCCEEDED', async () => {
        await createComponent();

        const initialPipelineCount = displayedPipelines().length;

        emitSubscriptionUpdate([succeededRequest]);
        await waitForPromises();

        const pipelines = displayedPipelines();
        expect(pipelines).toHaveLength(initialPipelineCount + 1);
        expect(pipelines[0].id).toBe('gid://gitlab/Ci::Pipeline/999');
      });

      it('updates badge count on SUCCEEDED', async () => {
        const element = document.createElement('div');
        document.body.appendChild(element);

        try {
          await createComponent();
          element.appendChild(wrapper.vm.$el);

          let eventCount = 0;
          const eventPromise = new Promise((resolve) => {
            element.addEventListener('update-pipelines-count', (event) => {
              eventCount += 1;
              if (eventCount === 1) {
                resolve(event.detail.pipelineCount);
              }
            });
          });

          emitSubscriptionUpdate([succeededRequest]);
          await waitForPromises();

          const newCount = await eventPromise;
          expect(newCount).toBe(2);
        } finally {
          element.remove();
        }
      });

      it('shows skeleton loader on IN_PROGRESS after debounce', async () => {
        await createComponent();

        expect(findPipelinesList().props('isCreatingPipeline')).toBe(false);

        emitSubscriptionUpdate([inProgressRequest]);
        await waitForPromises();

        expect(findPipelinesList().props('isCreatingPipeline')).toBe(false);

        jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
        await nextTick();

        expect(findPipelinesList().props('isCreatingPipeline')).toBe(true);
      });

      it('shows alert on FAILED', async () => {
        await createComponent();

        expect(findCreationFailedAlert().exists()).toBe(false);

        emitSubscriptionUpdate([failedRequest]);
        await waitForPromises();

        expect(findCreationFailedAlert().exists()).toBe(true);
        expect(findCreationFailedAlert().text()).toBe(
          'Pipeline creation failed. Please try again.',
        );
      });

      it('does not show alert on automatic FAILED', async () => {
        await createComponent();

        emitSubscriptionUpdate([automaticFailedRequest]);
        await waitForPromises();

        expect(findCreationFailedAlert().exists()).toBe(false);
      });

      it('shows alert again when a new request fails after dismissal', async () => {
        setupPipelineCreationRequestsResponse([failedRequest]);

        await createComponent();
        await findCreationFailedAlert().vm.$emit('dismiss');

        expect(findCreationFailedAlert().exists()).toBe(false);

        const newFailedRequest = generatePipelineCreationRequest({
          id: 'new-failed-request-uuid',
          status: 'FAILED',
          pipelineId: null,
          pipeline: null,
          error: 'Creation failed',
        });
        emitSubscriptionUpdate([failedRequest, newFailedRequest]);
        await waitForPromises();

        expect(findCreationFailedAlert().exists()).toBe(true);
      });

      it('does not re-show alert for an already dismissed request', async () => {
        setupPipelineCreationRequestsResponse([failedRequest]);

        await createComponent();
        await findCreationFailedAlert().vm.$emit('dismiss');

        emitSubscriptionUpdate([failedRequest]);
        await waitForPromises();

        expect(findCreationFailedAlert().exists()).toBe(false);
      });

      it('shows loading state on run pipeline button on IN_PROGRESS', async () => {
        setupDetachedPipelineResponse();
        await createComponent();

        expect(findRunPipelineBtn().props('isLoading')).toBe(false);

        emitSubscriptionUpdate([inProgressRequest]);
        await waitForPromises();

        expect(findRunPipelineBtn().props('isLoading')).toBe(true);
      });

      it('does not duplicate pipelines already in the list', async () => {
        await createComponent();

        emitSubscriptionUpdate([succeededRequest]);
        await waitForPromises();

        expect(displayedPipelines()).toHaveLength(2);

        const anotherSucceededRequest = generatePipelineCreationRequest({
          status: 'SUCCEEDED',
          pipelineId: 'gid://gitlab/Ci::Pipeline/1000',
        });

        emitSubscriptionUpdate([succeededRequest, anotherSucceededRequest]);
        await waitForPromises();

        const pipelines = displayedPipelines();
        expect(pipelines).toHaveLength(3);
        expect(pipelines[0].id).toBe('gid://gitlab/Ci::Pipeline/1000');
        expect(pipelines[1].id).toBe('gid://gitlab/Ci::Pipeline/999');
      });
    });
  });
});

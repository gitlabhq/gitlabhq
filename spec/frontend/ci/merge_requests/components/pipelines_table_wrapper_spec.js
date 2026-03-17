import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLoadingIcon, GlModal, GlKeysetPagination } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import Api from '~/api';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import { DEFAULT_MANUAL_ACTIONS_LIMIT } from '~/ci/constants';
import PipelinesTableWrapper from '~/ci/merge_requests/components/pipelines_table_wrapper.vue';
import { MR_PIPELINE_TYPE_DETACHED } from '~/ci/merge_requests/constants';
import getMergeRequestsPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import mrPipelineStatusesUpdatedSubscription from '~/ci/merge_requests/graphql/subscriptions/mr_pipeline_statuses_updated.subscription.graphql';
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
  mockPipelineUpdateResponseEmpty,
  mockPipelineUpdateResponse,
  generatePipelineCreationRequestsResponse,
  generatePipelineCreationSubscriptionResponse,
  generatePipelineCreationRequest,
} from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const $toast = {
  show: jest.fn(),
};

let wrapper;
let mergeRequestPipelinesRequest;
let cancelPipelineMutationRequest;
let retryPipelineMutationRequest;
let subscriptionHandler;
let pipelineCreationRequestsHandler;
let pipelineCreationSubscriptionHandler;
let mockPipelineCreationSubscription;
let apolloMock;
const showMock = jest.fn();

const defaultProvide = {
  graphqlPath: '/api/graphql/',
  mergeRequestId: 1,
  targetProjectFullPath: '/group/project',
};

const defaultProps = {
  canRunPipeline: true,
  projectId: '5',
  mergeRequestId: 3,
  errorStateSvgPath: 'error-svg',
  emptyStateSvgPath: 'empty-svg',
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

const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
  const handlers = [
    [getMergeRequestsPipelines, mergeRequestPipelinesRequest],
    [cancelPipelineMutation, cancelPipelineMutationRequest],
    [retryPipelineMutation, retryPipelineMutationRequest],
    [mrPipelineStatusesUpdatedSubscription, subscriptionHandler],
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
      manualActionsLimit: DEFAULT_MANUAL_ACTIONS_LIMIT,
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
    },
  });

  return waitForPromises();
};

const findEmptyState = () => wrapper.findByTestId('pipeline-empty-state');
const findErrorEmptyState = () => wrapper.findByTestId('pipeline-error-empty-state');
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findModal = () => wrapper.findComponent(GlModal);
const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');
const findPipelinesList = () => wrapper.findComponent(PipelinesTable);
const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
const findCreationFailedAlert = () => wrapper.findComponent(GlAlert);
const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');
const findPagination = () => wrapper.findComponent(GlKeysetPagination);

beforeEach(() => {
  mergeRequestPipelinesRequest = jest.fn();
  mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 1 }));

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
      expect(findErrorEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
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
        expect(findPipelinesList().props().pipelines).toHaveLength(1);
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
        expect(findRunPipelineBtn().exists()).toBe(true);
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

  describe('polling', () => {
    it('polls every 10 seconds', async () => {
      await createComponent();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(2);
    });

    describe('with pending pipelines from subscription', () => {
      const succeededRequest = generatePipelineCreationRequest({
        status: 'SUCCEEDED',
        pipelineId: 'gid://gitlab/Ci::Pipeline/999',
      });

      const addPipelineViaSubscription = async () => {
        mockPipelineCreationSubscription.next(
          generatePipelineCreationSubscriptionResponse({ requests: [succeededRequest] }),
        );
        await waitForPromises();
      };

      it('preserves pipelines not yet returned by server', async () => {
        await createComponent();
        await addPipelineViaSubscription();

        expect(findPipelinesList().props('pipelines')[0].id).toBe(999);

        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 1 }));
        apolloMock.defaultClient.resetStore();
        await waitForPromises();

        const pipelines = findPipelinesList().props('pipelines');
        expect(pipelines).toHaveLength(2);
        expect(pipelines[0].id).toBe(999);
      });

      it('does not duplicate pipeline once server returns it', async () => {
        await createComponent();
        await addPipelineViaSubscription();

        const responseWithNewPipeline = generateMRPipelinesResponse({ count: 2 });
        responseWithNewPipeline.data.project.mergeRequest.pipelines.nodes = [
          generateMockPipeline({ id: '999', status: 'RUNNING' }),
          generateMockPipeline({ id: '1', status: 'SUCCESS' }),
        ];
        mergeRequestPipelinesRequest.mockResolvedValue(responseWithNewPipeline);
        apolloMock.defaultClient.resetStore();
        await waitForPromises();

        const pipelineIds = findPipelinesList()
          .props('pipelines')
          .map((p) => p.id);
        expect(pipelineIds).toHaveLength(2);
        expect(pipelineIds.filter((id) => id === 999)).toHaveLength(1);
      });
    });
  });

  describe('when latest pipeline has detached flag', () => {
    beforeEach(async () => {
      const response = generateMRPipelinesResponse({
        mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
      });

      mergeRequestPipelinesRequest.mockResolvedValue(response);

      await createComponent();
    });

    it('renders the run pipeline button', () => {
      expect(findRunPipelineBtn().exists()).toBe(true);
      expect(findRunPipelineBtnMobile().exists()).toBe(true);
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

          await findRunPipelineBtn().trigger('click');

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

      it('on desktop, shows a security warning modal', async () => {
        await findRunPipelineBtn().trigger('click');

        expect(findModal()).not.toBeNull();
        expect(findRunPipelineBtn().props('loading')).toBe(false);
      });

      it('on mobile, shows a security warning modal', async () => {
        await findRunPipelineBtnMobile().trigger('click');

        expect(findModal()).not.toBeNull();
        expect(findRunPipelineBtn().props('loading')).toBe(false);
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

        await findRunPipelineBtn().trigger('click');

        expect(showMock).toHaveBeenCalled();
      });
    });

    describe('events', () => {
      const response = generateMRPipelinesResponse();
      const pipeline = response.data.project.mergeRequest.pipelines.nodes[0];

      beforeEach(async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(response);
        await createComponent();
      });

      describe('When cancelling a pipeline', () => {
        it('execute the cancel graphql mutation', async () => {
          expect(cancelPipelineMutationRequest.mock.calls).toHaveLength(0);

          findPipelinesList().vm.$emit('cancel-pipeline', pipeline);

          await waitForPromises();

          expect(cancelPipelineMutationRequest.mock.calls[0]).toEqual([
            { id: 'gid://gitlab/Ci::Pipeline/1' },
          ]);
        });
      });

      describe('When retrying a pipeline', () => {
        it('sends the retry action graphql mutation', async () => {
          expect(retryPipelineMutationRequest.mock.calls).toHaveLength(0);

          findPipelinesList().vm.$emit('retry-pipeline', pipeline);

          await waitForPromises();

          expect(retryPipelineMutationRequest.mock.calls[0]).toEqual([
            { id: 'gid://gitlab/Ci::Pipeline/1' },
          ]);
        });
      });

      describe('When refreshing a pipeline', () => {
        it('calls the apollo query again', async () => {
          expect(mergeRequestPipelinesRequest.mock.calls).toHaveLength(1);

          findPipelinesList().vm.$emit('refresh-pipelines-table');

          await waitForPromises();

          expect(mergeRequestPipelinesRequest.mock.calls).toHaveLength(2);
        });
      });
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

      it('skips subscription when there are no pipelines', async () => {
        mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 0 }));
        subscriptionHandler.mockResolvedValue(mockPipelineUpdateResponse);
        await createComponent();

        expect(subscriptionHandler).not.toHaveBeenCalled();
      });
    });
  });

  describe('pipeline creation requests', () => {
    const inProgressRequest = generatePipelineCreationRequest({
      status: 'IN_PROGRESS',
      pipelineId: null,
      pipeline: null,
    });
    const failedRequest = generatePipelineCreationRequest({
      status: 'FAILED',
      pipelineId: null,
      pipeline: null,
      error: 'Creation failed',
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
      });

      describe('run pipeline button', () => {
        beforeEach(() => {
          setupDetachedPipelineResponse();
        });

        it('shows loading state when IN_PROGRESS requests exist', async () => {
          setupPipelineCreationRequestsResponse([inProgressRequest]);

          await createComponent();

          expect(findRunPipelineBtn().props('loading')).toBe(true);
        });

        it('does not show toast when running pipeline', async () => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();

          await createComponent();

          await findRunPipelineBtn().trigger('click');
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

      await findRunPipelineBtn().trigger('click');

      wrapper.destroy();

      expect(clearTimeoutSpy).toHaveBeenCalled();
    });

    describe('subscription updates', () => {
      it('prepends new pipeline to list on SUCCEEDED', async () => {
        await createComponent();

        const initialPipelineCount = findPipelinesList().props('pipelines').length;

        emitSubscriptionUpdate([succeededRequest]);
        await waitForPromises();

        const pipelines = findPipelinesList().props('pipelines');
        expect(pipelines).toHaveLength(initialPipelineCount + 1);
        expect(pipelines[0].id).toBe(999);
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
              if (eventCount === 2) {
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

      it('shows loading state on run pipeline button on IN_PROGRESS', async () => {
        setupDetachedPipelineResponse();
        await createComponent();

        expect(findRunPipelineBtn().props('loading')).toBe(false);

        emitSubscriptionUpdate([inProgressRequest]);
        await waitForPromises();

        expect(findRunPipelineBtn().props('loading')).toBe(true);
      });

      it('does not duplicate pipelines already in the list', async () => {
        await createComponent();

        emitSubscriptionUpdate([succeededRequest]);
        await waitForPromises();

        expect(findPipelinesList().props('pipelines')).toHaveLength(2);

        const anotherSucceededRequest = generatePipelineCreationRequest({
          status: 'SUCCEEDED',
          pipelineId: 'gid://gitlab/Ci::Pipeline/1000',
        });

        emitSubscriptionUpdate([succeededRequest, anotherSucceededRequest]);
        await waitForPromises();

        const pipelines = findPipelinesList().props('pipelines');
        expect(pipelines).toHaveLength(3);
        expect(pipelines[0].id).toBe(1000);
        expect(pipelines[1].id).toBe(999);
      });
    });
  });
});

import { GlLoadingIcon, GlKeysetPagination } from '@gitlab/ui';
import { createMockSubscription } from 'mock-apollo-client';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitPipelinesList from '~/ci/commit/components/commit_pipelines_list.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';
import PipelinesErrorState from '~/ci/common/empty_state/pipelines_error_state.vue';
import getCommitPipelines from '~/ci/commit/graphql/queries/get_commit_pipelines.query.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import commitPipelineStatusesUpdatedSubscription from '~/ci/commit/graphql/subscriptions/commit_pipeline_statuses_updated.subscription.graphql';
import {
  projectFullPath,
  projectId,
  commitSha,
  defaultCommitPipelinesResponse,
  paginatedCommitPipelinesResponse,
  emptyCommitPipelinesResponse,
  generateStatusesSubscriptionEvent,
  cancelPipelineResponse,
  retryPipelineResponse,
  retryPipelineResponseWithErrors,
} from '../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('CommitPipelinesList', () => {
  let wrapper;
  let apolloProvider;
  let mockSubscription;
  let subscriptionHandler;

  let successHandler;
  let emptyHandler;
  let failedHandler;
  let cancelHandler;
  let retryHandler;

  const emitStatusUpdate = (data) => mockSubscription.next(generateStatusesSubscriptionEvent(data));

  const createComponent = ({ requestHandlers = [[getCommitPipelines, successHandler]] } = {}) => {
    apolloProvider = createMockApollo(requestHandlers);

    subscriptionHandler = jest.fn(() => {
      mockSubscription = createMockSubscription();
      return mockSubscription;
    });
    apolloProvider.defaultClient.setRequestHandler(
      commitPipelineStatusesUpdatedSubscription,
      subscriptionHandler,
    );

    wrapper = shallowMountExtended(CommitPipelinesList, {
      propsData: { projectFullPath, commitSha },
      apolloProvider,
    });
  };

  const findTable = () => wrapper.findComponent(PipelinesTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(PipelinesEmptyState);
  const findErrorState = () => wrapper.findComponent(PipelinesErrorState);
  const findPagination = () => wrapper.findComponent(GlKeysetPagination);

  beforeEach(() => {
    successHandler = jest.fn().mockResolvedValue(defaultCommitPipelinesResponse);
    emptyHandler = jest.fn().mockResolvedValue(emptyCommitPipelinesResponse);
    failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    cancelHandler = jest.fn().mockResolvedValue(cancelPipelineResponse);
    retryHandler = jest.fn().mockResolvedValue(retryPipelineResponse);
  });

  describe('while loading', () => {
    it('shows the loading icon and no table', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when the query succeeds', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('queries pipelines for the commit SHA', () => {
      expect(successHandler).toHaveBeenCalledWith(
        expect.objectContaining({ fullPath: projectFullPath, sha: commitSha }),
      );
    });

    it('renders the table with the returned pipelines', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findTable().props('pipelines')).toHaveLength(2);
    });

    it('does not render empty or error states', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findErrorState().exists()).toBe(false);
    });
  });

  describe('when there are no pipelines', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: [[getCommitPipelines, emptyHandler]] });
      await waitForPromises();
    });

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findEmptyState().props('title')).toBe('There are currently no pipelines.');

      expect(findTable().exists()).toBe(false);
    });
  });

  describe('when the query fails', () => {
    beforeEach(async () => {
      createComponent({ requestHandlers: [[getCommitPipelines, failedHandler]] });
      await waitForPromises();
    });

    it('renders the error state', () => {
      expect(findErrorState().exists()).toBe(true);
      expect(findTable().exists()).toBe(false);
    });
  });

  describe('pipeline count badge', () => {
    it('dispatches update-pipelines-count with the total count on the parent element', async () => {
      const container = document.createElement('div');
      document.body.appendChild(container);

      const listener = jest.fn();
      container.addEventListener('update-pipelines-count', listener);

      createComponent();
      container.appendChild(wrapper.vm.$el);

      await waitForPromises();

      expect(listener).toHaveBeenCalledTimes(1);
      expect(listener.mock.calls[0][0].detail).toEqual({ pipelineCount: 2 });

      container.remove();
    });
  });

  describe('pagination', () => {
    beforeEach(async () => {
      successHandler.mockResolvedValue(paginatedCommitPipelinesResponse);
      createComponent();
      await waitForPromises();
    });

    it('requests the next page using the end cursor', async () => {
      findPagination().vm.$emit('next');
      await waitForPromises();

      expect(successHandler).toHaveBeenLastCalledWith({
        fullPath: projectFullPath,
        sha: commitSha,
        first: 15,
        last: null,
        before: null,
        after: 'END_CURSOR',
      });
    });

    it('still applies newly created pipelines after navigating to the next page and back to the first page', async () => {
      findPagination().vm.$emit('next');
      await waitForPromises();

      findPagination().vm.$emit('prev');
      await waitForPromises();

      // Back to first page
      emitStatusUpdate({ id: 9999 });
      await waitForPromises();

      expect(findTable().props('pipelines')[0].id).toBe('gid://gitlab/Ci::Pipeline/9999');
    });
  });

  describe('cancel and retry', () => {
    beforeEach(async () => {
      createComponent({
        requestHandlers: [
          [getCommitPipelines, successHandler],
          [cancelPipelineMutation, cancelHandler],
          [retryPipelineMutation, retryHandler],
        ],
      });
      await waitForPromises();
    });

    it('cancels a pipeline using its GraphQL id', async () => {
      findTable().vm.$emit('cancel-pipeline', { id: 'gid://gitlab/Ci::Pipeline/701' });
      await waitForPromises();

      expect(cancelHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/Ci::Pipeline/701' });
    });

    it('retries a pipeline using its GraphQL id', async () => {
      findTable().vm.$emit('retry-pipeline', { id: 'gid://gitlab/Ci::Pipeline/701' });
      await waitForPromises();

      expect(retryHandler).toHaveBeenCalledWith({ id: 'gid://gitlab/Ci::Pipeline/701' });
    });

    it('alerts when the mutation returns an error', async () => {
      createComponent({
        requestHandlers: [
          [getCommitPipelines, successHandler],
          [retryPipelineMutation, jest.fn().mockResolvedValue(retryPipelineResponseWithErrors)],
        ],
      });
      await waitForPromises();

      findTable().vm.$emit('retry-pipeline', { id: 'gid://gitlab/Ci::Pipeline/701' });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'The pipeline could not be retried.',
      });
    });
  });

  describe('live updates via subscription', () => {
    beforeEach(async () => {
      successHandler.mockResolvedValue(paginatedCommitPipelinesResponse);
      createComponent();
      await waitForPromises();
    });

    it('subscribes with the project id and commit sha', () => {
      expect(subscriptionHandler).toHaveBeenCalledWith({ projectId, sha: commitSha });
    });

    it('updates the displayed status of a shown pipeline from the subscription payload', async () => {
      expect(findTable().props('pipelines')[0].detailedStatus.name).toBe('PENDING');

      emitStatusUpdate({ id: findTable().props('pipelines')[0].id, status: 'SUCCESS' });
      await waitForPromises();

      expect(findTable().props('pipelines')[0].detailedStatus.name).toBe('SUCCESS');

      // Confirm the status came from the subscription payload, no extra query was issued.
      expect(successHandler).toHaveBeenCalledTimes(1);
    });

    it('when on first page, prepends a new pipeline from subscription', async () => {
      const firstId = findTable().props('pipelines')[0].id;

      emitStatusUpdate({ id: 9999, status: 'SUCCESS' });
      await waitForPromises();

      expect(findTable().props('pipelines')[0].id).toEqual('gid://gitlab/Ci::Pipeline/9999');
      expect(findTable().props('pipelines')[0].detailedStatus.name).toEqual('SUCCESS');

      expect(findTable().props('pipelines')[1].id).toEqual(firstId);
      expect(findTable().props('pipelines')[1].detailedStatus.name).toEqual('PENDING');

      // Confirm the status came from the subscription payload, no extra query was issued.
      expect(successHandler).toHaveBeenCalledTimes(1);
    });

    it('when on later page, does not prepend a pipeline', async () => {
      findPagination().vm.$emit('next');
      await waitForPromises();

      const before = findTable()
        .props('pipelines')
        .map((p) => p.id);

      emitStatusUpdate({ id: 9999, status: 'SUCCESS' });
      await waitForPromises();

      expect(
        findTable()
          .props('pipelines')
          .map((p) => p.id),
      ).toEqual(before);
    });
  });
});

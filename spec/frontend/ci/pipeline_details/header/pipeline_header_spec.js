import { GlAlert, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PipelineHeader from '~/ci/pipeline_details/header/pipeline_header.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '~/ci/pipeline_details/graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import HeaderActions from '~/ci/pipeline_details/header/components/header_actions.vue';
import HeaderBadges from '~/ci/pipeline_details/header/components/header_badges.vue';
import getPipelineDetailsQuery from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import {
  pipelineHeaderSuccess,
  pipelineHeaderRunning,
  pipelineHeaderRunningWithDuration,
  pipelineHeaderFailed,
  pipelineRetryMutationResponseSuccess,
  pipelineCancelMutationResponseSuccess,
  pipelineDeleteMutationResponseSuccess,
  pipelineRetryMutationResponseFailed,
  pipelineCancelMutationResponseFailed,
  pipelineDeleteMutationResponseFailed,
} from '../mock_data';

Vue.use(VueApollo);

describe('Pipeline header', () => {
  let wrapper;

  const successHandler = jest.fn().mockResolvedValue(pipelineHeaderSuccess);
  const runningHandler = jest.fn().mockResolvedValue(pipelineHeaderRunning);
  const runningHandlerWithDuration = jest.fn().mockResolvedValue(pipelineHeaderRunningWithDuration);
  const failedHandler = jest.fn().mockResolvedValue(pipelineHeaderFailed);

  const retryMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(pipelineRetryMutationResponseSuccess);
  const cancelMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(pipelineCancelMutationResponseSuccess);
  const deleteMutationHandlerSuccess = jest
    .fn()
    .mockResolvedValue(pipelineDeleteMutationResponseSuccess);
  const retryMutationHandlerFailed = jest
    .fn()
    .mockResolvedValue(pipelineRetryMutationResponseFailed);
  const cancelMutationHandlerFailed = jest
    .fn()
    .mockResolvedValue(pipelineCancelMutationResponseFailed);
  const deleteMutationHandlerFailed = jest
    .fn()
    .mockResolvedValue(pipelineDeleteMutationResponseFailed);

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findStatus = () => wrapper.findComponent(CiIcon);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBadges = () => wrapper.findComponent(HeaderBadges);
  const findHeaderActions = () => wrapper.findComponent(HeaderActions);
  const findCreatedTimeAgo = () => wrapper.findByTestId('pipeline-created-time-ago');
  const findFinishedTimeAgo = () => wrapper.findByTestId('pipeline-finished-time-ago');
  const findFinishedCreatedTimeAgo = () =>
    wrapper.findByTestId('pipeline-finished-created-time-ago');
  const findPipelineName = () => wrapper.findByTestId('pipeline-name');
  const findCommitTitle = () => wrapper.findByTestId('pipeline-commit-title');
  const findTotalJobs = () => wrapper.findByTestId('total-jobs');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findCommitCopyButton = () => wrapper.findByTestId('commit-copy-sha');
  const findPipelineRunningText = () => wrapper.findByTestId('pipeline-running-text').text();
  const findPipelineRefText = () => wrapper.findByTestId('pipeline-ref-text').text();
  const findPipelineUserLink = () => wrapper.findByTestId('pipeline-user-link');
  const findPipelineDuration = () => wrapper.findByTestId('pipeline-duration-text');

  const clickActionButton = (action, id) => {
    findHeaderActions().vm.$emit(action, id);
  };

  const defaultHandlers = [[getPipelineDetailsQuery, successHandler]];

  const defaultProvideOptions = {
    identityVerificationRequired: false,
    identityVerificationPath: '#',
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
    },
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers) => {
    wrapper = shallowMountExtended(PipelineHeader, {
      provide: defaultProvideOptions,
      stubs: { GlSprintf },
      apolloProvider: createMockApolloProvider(handlers),
    });

    return waitForPromises();
  };

  describe('loading state', () => {
    it('shows a loading state while graphQL is fetching initial data', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('defaults', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('does not display loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays pipeline status', () => {
      expect(findStatus().exists()).toBe(true);
    });

    it('displays pipeline name', () => {
      expect(findPipelineName().text()).toBe('Build pipeline');
    });

    it('displays total jobs', () => {
      expect(findTotalJobs().text()).toBe('3 jobs');
    });

    it('has link to commit', () => {
      const {
        data: {
          project: { pipeline },
        },
      } = pipelineHeaderSuccess;

      expect(findCommitLink().attributes('href')).toBe(pipeline.commit.webPath);
      expect(findCommitLink().text()).toBe(pipeline.commit.shortId);
    });

    it('copies the full commit ID', () => {
      const {
        data: {
          project: { pipeline },
        },
      } = pipelineHeaderSuccess;

      expect(findCommitCopyButton().props('text')).toBe(pipeline.commit.sha);
    });

    it('displays badges', () => {
      expect(findBadges().exists()).toBe(true);
    });

    it('passes pipeline prop to HeaderBadges component', () => {
      expect(findBadges().props('pipeline')).toEqual(pipelineHeaderSuccess.data.project.pipeline);
    });

    it('displays ref text', () => {
      expect(findPipelineRefText()).toBe('Related merge request !1 to merge master into feature');
    });

    it('displays pipeline user link with required user popover attributes', () => {
      const {
        data: {
          project: {
            pipeline: { user },
          },
        },
      } = pipelineHeaderSuccess;

      const userId = getIdFromGraphQLId(user.id).toString();

      expect(findPipelineUserLink().classes()).toContain('js-user-link');
      expect(findPipelineUserLink().attributes('data-user-id')).toBe(userId);
      expect(findPipelineUserLink().attributes('data-username')).toBe(user.username);
      expect(findPipelineUserLink().attributes('href')).toBe(user.webUrl);
    });
  });

  describe('without pipeline name', () => {
    it('displays commit title', async () => {
      await createComponent([[getPipelineDetailsQuery, runningHandler]]);

      const expectedTitle = pipelineHeaderSuccess.data.project.pipeline.commit.title;

      expect(findPipelineName().exists()).toBe(false);
      expect(findCommitTitle().text()).toBe(expectedTitle);
    });
  });

  describe('finished pipeline', () => {
    it('displays finished time and created time', async () => {
      await createComponent();

      expect(findFinishedTimeAgo().exists()).toBe(true);
      expect(findFinishedCreatedTimeAgo().exists()).toBe(true);
    });

    it('displays pipeline duartion text', async () => {
      await createComponent();

      expect(findPipelineDuration().text()).toBe(
        '120 minutes 10 seconds, queued for 3,600 seconds',
      );
    });
  });

  describe('running pipeline', () => {
    beforeEach(() => {
      return createComponent([[getPipelineDetailsQuery, runningHandler]]);
    });

    it('does not display finished time ago', () => {
      expect(findFinishedTimeAgo().exists()).toBe(false);
      expect(findFinishedCreatedTimeAgo().exists()).toBe(false);
    });

    it('does not display pipeline duration text', () => {
      expect(findPipelineDuration().exists()).toBe(false);
    });

    it('displays pipeline running text', () => {
      expect(findPipelineRunningText()).toBe('In progress, queued for 3,600 seconds');
    });

    it('displays created time ago', () => {
      expect(findCreatedTimeAgo().exists()).toBe(true);
    });
  });

  describe('running pipeline with duration', () => {
    beforeEach(() => {
      return createComponent([[getPipelineDetailsQuery, runningHandlerWithDuration]]);
    });

    it('does not display pipeline duration text', () => {
      expect(findPipelineDuration().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    it('passes correct props to the header actions component', async () => {
      await createComponent([
        [getPipelineDetailsQuery, failedHandler],
        [retryPipelineMutation, retryMutationHandlerSuccess],
      ]);

      expect(findHeaderActions().props()).toEqual({
        isCanceling: false,
        isDeleting: false,
        isRetrying: false,
        pipeline: pipelineHeaderFailed.data.project.pipeline,
      });
    });

    describe('retry action', () => {
      beforeEach(() => {
        return createComponent([
          [getPipelineDetailsQuery, failedHandler],
          [retryPipelineMutation, retryMutationHandlerSuccess],
        ]);
      });

      it('should call retryPipeline Mutation with pipeline id', async () => {
        clickActionButton('retryPipeline', pipelineHeaderFailed.data.project.pipeline.id);

        await nextTick();

        expect(findHeaderActions().props('isRetrying')).toBe(true);
        expect(retryMutationHandlerSuccess).toHaveBeenCalledWith({
          id: pipelineHeaderFailed.data.project.pipeline.id,
        });
        expect(findAlert().exists()).toBe(false);

        await waitForPromises();

        expect(findHeaderActions().props('isRetrying')).toBe(false);
      });
    });

    describe('retry action failed', () => {
      beforeEach(() => {
        return createComponent([
          [getPipelineDetailsQuery, failedHandler],
          [retryPipelineMutation, retryMutationHandlerFailed],
        ]);
      });

      it('should display error message on failure', async () => {
        clickActionButton('retryPipeline', pipelineHeaderFailed.data.project.pipeline.id);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });

      it('retry button loading state should reset on error', async () => {
        clickActionButton('retryPipeline', pipelineHeaderFailed.data.project.pipeline.id);

        await nextTick();

        expect(findHeaderActions().props('isRetrying')).toBe(true);

        await waitForPromises();

        expect(findHeaderActions().props('isRetrying')).toBe(false);
      });
    });

    describe('cancel action', () => {
      describe('with permissions', () => {
        it('should call cancelPipeline Mutation with pipeline id', async () => {
          await createComponent([
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerSuccess],
          ]);

          clickActionButton('cancelPipeline', pipelineHeaderRunning.data.project.pipeline.id);

          await nextTick();

          expect(findHeaderActions().props('isCanceling')).toBe(true);
          expect(cancelMutationHandlerSuccess).toHaveBeenCalledWith({
            id: pipelineHeaderRunning.data.project.pipeline.id,
          });
          expect(findAlert().exists()).toBe(false);

          await waitForPromises();

          expect(findHeaderActions().props('isCanceling')).toBe(false);
        });

        it('should display error message on failure', async () => {
          await createComponent([
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerFailed],
          ]);

          clickActionButton('cancelPipeline', pipelineHeaderRunning.data.project.pipeline.id);

          await waitForPromises();

          expect(findAlert().exists()).toBe(true);
        });
      });
    });

    describe('delete action', () => {
      it('should call deletePipeline Mutation with pipeline id when modal is submitted', async () => {
        await createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerSuccess],
        ]);

        clickActionButton('deletePipeline', pipelineHeaderSuccess.data.project.pipeline.id);

        await nextTick();

        expect(findHeaderActions().props('isDeleting')).toBe(true);
        expect(deleteMutationHandlerSuccess).toHaveBeenCalledWith({
          id: pipelineHeaderSuccess.data.project.pipeline.id,
        });

        await waitForPromises();

        expect(findHeaderActions().props('isDeleting')).toBe(false);
      });

      it('should display error message on failure', async () => {
        await createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerFailed],
        ]);

        clickActionButton('deletePipeline', pipelineHeaderSuccess.data.project.pipeline.id);

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });

      it('delete button loading state should reset on error', async () => {
        await createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerFailed],
        ]);

        clickActionButton('deletePipeline', pipelineHeaderSuccess.data.project.pipeline.id);

        await nextTick();

        expect(findHeaderActions().props('isDeleting')).toBe(true);

        await waitForPromises();

        expect(findHeaderActions().props('isDeleting')).toBe(false);
      });
    });
  });
});

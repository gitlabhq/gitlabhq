import { GlAlert, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PipelineHeader from '~/ci/pipeline_details/header/pipeline_header.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import { setFaviconOverlay, resetFavicon } from '~/lib/utils/favicon';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '~/ci/pipeline_details/graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import HeaderActions from '~/ci/pipeline_details/header/components/header_actions.vue';
import HeaderBadges from '~/ci/pipeline_details/header/components/header_badges.vue';
import getPipelineDetailsQuery from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import pipelineHeaderStatusUpdatedSubscription from '~/ci/pipeline_details/header/graphql/subscriptions/pipeline_header_status_updated.subscription.graphql';

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
  mockPipelineStatusUpdatedResponse,
  mockPipelineStatusNullResponse,
} from '../mock_data';

jest.mock('~/lib/utils/favicon');

Vue.use(VueApollo);

describe('Pipeline header', () => {
  let wrapper;
  let apolloProvider;

  const successHandler = jest.fn().mockResolvedValue(pipelineHeaderSuccess);
  const runningHandler = jest.fn().mockResolvedValue(pipelineHeaderRunning);
  const runningHandlerWithDuration = jest.fn().mockResolvedValue(pipelineHeaderRunningWithDuration);
  const failedHandler = jest.fn().mockResolvedValue(pipelineHeaderFailed);
  const subscriptionHandler = jest.fn().mockResolvedValue(mockPipelineStatusUpdatedResponse);
  const subscriptionNullHandler = jest.fn().mockResolvedValue(mockPipelineStatusNullResponse);

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
  const findCreatedStatus = () => wrapper.findByTestId('pipeline-created-status');
  const findCreatedTimeAgo = () => wrapper.findByTestId('pipeline-created-time-ago');
  const findFinishedTimeAgo = () => wrapper.findByTestId('pipeline-finished-time-ago');
  const findPipelineId = () => wrapper.findByTestId('pipeline-id');
  const findPipelineTitle = () => wrapper.findByTestId('pipeline-title');
  const findTotalJobs = () => wrapper.findByTestId('total-jobs');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findCommitTitle = () => wrapper.findByTestId('commit-title');
  const findCommitCopyButton = () => wrapper.findByTestId('commit-copy-sha');
  const findPipelineRunningText = () => wrapper.findByTestId('pipeline-running-text').text();
  const findPipelineRefText = () => wrapper.findByTestId('pipeline-ref-text').text();
  const findPipelineUserLink = () => wrapper.findByTestId('pipeline-user-link');
  const findPipelineDuration = () => wrapper.findByTestId('pipeline-duration-text');

  const clickActionButton = (action, id) => {
    findHeaderActions().vm.$emit(action, id);
  };

  const defaultHandlers = [
    [getPipelineDetailsQuery, successHandler],
    [deletePipelineMutation, deleteMutationHandlerSuccess],
    [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
  ];

  const createComponent = ({ handlers = defaultHandlers, provide = {} } = {}) => {
    apolloProvider = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineHeader, {
      provide: {
        identityVerificationRequired: false,
        identityVerificationPath: '#',
        pipelineIid: 1,
        pipelineId: 100,
        paths: {
          pipelinesPath: '/namespace/my-project/-/pipelines',
          fullProject: '/namespace/my-project',
        },
        ...provide,
      },
      stubs: {
        GlSprintf,
        TimeAgoTooltip: {
          props: ['time'],
          template: '<span>{{time}}</span>',
        },
      },
      apolloProvider,
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
      expect(findPipelineTitle().text()).toBe('Build pipeline');
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

    describe('when ci_show_pipeline_name_instead_of_commit_title is disabled', () => {
      it('displays commit title', () => {
        expect(findCommitTitle().exists()).toBe(false);
      });
    });

    describe('when ci_show_pipeline_name_instead_of_commit_title is enabled', () => {
      it('displays commit title', async () => {
        await createComponent({
          provide: {
            glFeatures: {
              ciShowPipelineNameInsteadOfCommitTitle: true,
            },
          },
        });

        const {
          data: {
            project: { pipeline },
          },
        } = pipelineHeaderSuccess;

        expect(findCommitTitle().text()).toBe(pipeline.commit.title);
      });
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

    it('passes pipeline prop to HeaderBadges component', async () => {
      await createComponent();

      expect(findBadges().props('pipeline')).toEqual(pipelineHeaderSuccess.data.project.pipeline);
    });

    it('displays ref text', () => {
      expect(findPipelineRefText()).toBe('Related merge request !1 to merge master into feature');
    });

    it('displays pipeline user link with required user popover attributes', () => {
      const { user } = pipelineHeaderSuccess.data.project.pipeline;

      const userId = getIdFromGraphQLId(user.id).toString();

      expect(findPipelineUserLink().classes()).toContain('js-user-link');
      expect(findPipelineUserLink().attributes('data-user-id')).toBe(userId);
      expect(findPipelineUserLink().attributes('data-username')).toBe(user.username);
      expect(findPipelineUserLink().attributes('href')).toBe(user.webUrl);
    });
  });

  describe('without pipeline name (from workflow:name)', () => {
    describe('when ci_show_pipeline_name_instead_of_commit_title is disabled', () => {
      it('displays commit title', async () => {
        await createComponent({
          handlers: [
            [getPipelineDetailsQuery, runningHandler],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });

        const commitTitle = pipelineHeaderRunning.data.project.pipeline.commit.title;

        expect(findPipelineId().exists()).toBe(false);
        expect(findPipelineTitle().text()).toBe(commitTitle);
      });
    });

    describe('when ci_show_pipeline_name_instead_of_commit_title is enabled', () => {
      it('shows a pipeline id', async () => {
        await createComponent({
          provide: {
            glFeatures: { ciShowPipelineNameInsteadOfCommitTitle: true },
          },
          handlers: [
            [getPipelineDetailsQuery, runningHandler],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });

        const id = getIdFromGraphQLId(pipelineHeaderRunning.data.project.pipeline.id);

        // only id is shown
        expect(findPipelineId().text()).toBe(`#${id}`);
        expect(findPipelineTitle().exists()).toBe(false);
      });
    });
  });

  describe('pipeline created/finished status', () => {
    const { createdAt, finishedAt, user } = pipelineHeaderSuccess.data.project.pipeline;

    it.each`
      createdAt    | finishedAt    | user    | expectedText
      ${createdAt} | ${finishedAt} | ${user} | ${`Created ${createdAt} by ${user.name}, finished ${finishedAt}`}
      ${createdAt} | ${finishedAt} | ${null} | ${`Created ${createdAt}, finished ${finishedAt}`}
      ${createdAt} | ${null}       | ${user} | ${`Created ${createdAt} by ${user.name}`}
      ${createdAt} | ${null}       | ${null} | ${`Created ${createdAt}`}
      ${null}      | ${finishedAt} | ${user} | ${`Created by ${user.name}, finished ${finishedAt}`}
      ${null}      | ${finishedAt} | ${null} | ${`Finished ${finishedAt}`}
      ${null}      | ${null}       | ${user} | ${`Created by ${user.name}`}
      ${null}      | ${null}       | ${null} | ${''}
    `('displays "$expectedText"', async ({ expectedText, ...pipeline }) => {
      successHandler.mockResolvedValueOnce({
        data: {
          project: {
            id: 'gid://gitlab/Project/1',
            pipeline: {
              ...pipelineHeaderSuccess.data.project.pipeline,
              ...pipeline,
            },
          },
        },
      });

      await createComponent();

      expect(findCreatedStatus().text()).toMatchInterpolatedText(expectedText);

      if (pipeline.createdAt) {
        expect(findCreatedTimeAgo().props('time')).toBe(pipeline.createdAt);
      } else {
        expect(findCreatedTimeAgo().exists()).toBe(false);
      }

      if (pipeline.finishedAt) {
        expect(findFinishedTimeAgo().props('time')).toBe(pipeline.finishedAt);
      } else {
        expect(findFinishedTimeAgo().exists()).toBe(false);
      }
    });

    it('displays pipeline duration text', async () => {
      await createComponent();

      expect(findPipelineDuration().text()).toBe(
        '120 minutes 10 seconds, queued for 3,600 seconds',
      );
    });
  });

  describe('running pipeline', () => {
    beforeEach(() => {
      return createComponent({
        handlers: [
          [getPipelineDetailsQuery, runningHandler],
          [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
        ],
      });
    });

    it('does not display pipeline duration text', () => {
      expect(findPipelineDuration().exists()).toBe(false);
    });

    it('displays pipeline running text', () => {
      expect(findPipelineRunningText()).toBe('In progress, queued for 3,600 seconds');
    });
  });

  describe('running pipeline with duration', () => {
    beforeEach(() => {
      return createComponent({
        handlers: [
          [getPipelineDetailsQuery, runningHandlerWithDuration],
          [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
        ],
      });
    });

    it('does not display pipeline duration text', () => {
      expect(findPipelineDuration().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    it('passes correct props to the header actions component', async () => {
      await createComponent({
        handlers: [
          [getPipelineDetailsQuery, failedHandler],
          [retryPipelineMutation, retryMutationHandlerSuccess],
          [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
        ],
      });

      expect(findHeaderActions().props()).toEqual({
        isCanceling: false,
        isDeleting: false,
        isRetrying: false,
        pipeline: pipelineHeaderFailed.data.project.pipeline,
      });
    });

    describe('retry action', () => {
      beforeEach(() => {
        return createComponent({
          handlers: [
            [getPipelineDetailsQuery, failedHandler],
            [retryPipelineMutation, retryMutationHandlerSuccess],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });
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
        return createComponent({
          handlers: [
            [getPipelineDetailsQuery, failedHandler],
            [retryPipelineMutation, retryMutationHandlerFailed],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });
      });

      it('should display error message on failure', async () => {
        clickActionButton('retryPipeline', pipelineHeaderFailed.data.project.pipeline.id);

        await waitForPromises();

        expect(findAlert().props('title')).toBe('An error occurred while making the request.');
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
          await createComponent({
            handlers: [
              [getPipelineDetailsQuery, runningHandler],
              [cancelPipelineMutation, cancelMutationHandlerSuccess],
              [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
            ],
          });

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
          await createComponent({
            handlers: [
              [getPipelineDetailsQuery, runningHandler],
              [cancelPipelineMutation, cancelMutationHandlerFailed],
              [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
            ],
          });

          clickActionButton('cancelPipeline', pipelineHeaderRunning.data.project.pipeline.id);

          await waitForPromises();

          expect(findAlert().props('title')).toBe('An error occurred while making the request.');
        });
      });
    });

    describe('delete action', () => {
      it('should call deletePipeline Mutation with pipeline id when modal is submitted', async () => {
        await createComponent();

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
        await createComponent({
          handlers: [
            [getPipelineDetailsQuery, successHandler],
            [deletePipelineMutation, deleteMutationHandlerFailed],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });

        clickActionButton('deletePipeline', pipelineHeaderSuccess.data.project.pipeline.id);

        await waitForPromises();

        expect(findAlert().props('title')).toBe('An error occurred while deleting the pipeline.');
      });

      it('delete button loading state should reset on error', async () => {
        await createComponent({
          handlers: [
            [getPipelineDetailsQuery, successHandler],
            [deletePipelineMutation, deleteMutationHandlerFailed],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
          ],
        });

        clickActionButton('deletePipeline', pipelineHeaderSuccess.data.project.pipeline.id);

        await nextTick();

        expect(findHeaderActions().props('isDeleting')).toBe(true);

        await waitForPromises();

        expect(findHeaderActions().props('isDeleting')).toBe(false);
      });
    });

    describe('subscription', () => {
      it('calls subscription with correct variables', async () => {
        await createComponent({
          handlers: [
            [getPipelineDetailsQuery, successHandler],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionHandler],
          ],
        });

        const {
          data: {
            project: { pipeline },
          },
        } = pipelineHeaderSuccess;

        expect(subscriptionHandler).toHaveBeenCalledWith({
          pipelineId: pipeline.id,
        });
      });

      it('does not make redundant subscription calls for refetches', async () => {
        await createComponent({
          handlers: [
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerSuccess],
            [pipelineHeaderStatusUpdatedSubscription, subscriptionHandler],
          ],
        });

        expect(subscriptionHandler).toHaveBeenCalledTimes(1);

        clickActionButton('cancelPipeline', pipelineHeaderRunning.data.project.pipeline.id);

        await nextTick();

        expect(subscriptionHandler).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('favicon', () => {
    beforeEach(() => {
      setFaviconOverlay.mockClear();
      resetFavicon.mockClear();
    });

    it('sets favicon overlay when pipeline has a favicon', async () => {
      await createComponent();

      const {
        data: {
          project: {
            pipeline: { detailedStatus },
          },
        },
      } = pipelineHeaderSuccess;

      expect(setFaviconOverlay).toHaveBeenCalledWith(detailedStatus.favicon);
    });

    it('resets favicon when component is destroyed', async () => {
      await createComponent();

      wrapper.destroy();

      expect(resetFavicon).toHaveBeenCalled();
    });

    it('updates favicon when pipeline status changes', async () => {
      await createComponent({
        handlers: [
          [getPipelineDetailsQuery, runningHandler],
          [pipelineHeaderStatusUpdatedSubscription, subscriptionNullHandler],
        ],
      });

      const {
        data: {
          project: {
            pipeline: { detailedStatus },
          },
        },
      } = pipelineHeaderRunning;

      expect(setFaviconOverlay).toHaveBeenCalledWith(detailedStatus.favicon);
    });
  });
});

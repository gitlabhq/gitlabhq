import { GlAlert, GlBadge, GlLoadingIcon, GlModal, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PipelineDetailsHeader from '~/ci/pipeline_details/header/pipeline_details_header.vue';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL } from '~/ci/constants';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '~/ci/pipeline_details/graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import getPipelineDetailsQuery from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import {
  pipelineHeaderSuccess,
  pipelineHeaderRunning,
  pipelineHeaderRunningNoPermissions,
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

describe('Pipeline details header', () => {
  let wrapper;
  let glModalDirective;

  const successHandler = jest.fn().mockResolvedValue(pipelineHeaderSuccess);
  const runningHandler = jest.fn().mockResolvedValue(pipelineHeaderRunning);
  const runningHandlerNoPermissions = jest
    .fn()
    .mockResolvedValue(pipelineHeaderRunningNoPermissions);
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
  const findAllBadges = () => wrapper.findAllComponents(GlBadge);
  const findDeleteModal = () => wrapper.findComponent(GlModal);
  const findCreatedTimeAgo = () => wrapper.findByTestId('pipeline-created-time-ago');
  const findFinishedTimeAgo = () => wrapper.findByTestId('pipeline-finished-time-ago');
  const findPipelineName = () => wrapper.findByTestId('pipeline-name');
  const findCommitTitle = () => wrapper.findByTestId('pipeline-commit-title');
  const findTotalJobs = () => wrapper.findByTestId('total-jobs');
  const findCommitLink = () => wrapper.findByTestId('commit-link');
  const findPipelineRunningText = () => wrapper.findByTestId('pipeline-running-text').text();
  const findPipelineRefText = () => wrapper.findByTestId('pipeline-ref-text').text();
  const findRetryButton = () => wrapper.findByTestId('retry-pipeline');
  const findCancelButton = () => wrapper.findByTestId('cancel-pipeline');
  const findDeleteButton = () => wrapper.findByTestId('delete-pipeline');
  const findPipelineUserLink = () => wrapper.findByTestId('pipeline-user-link');
  const findPipelineDuration = () => wrapper.findByTestId('pipeline-duration-text');

  const defaultHandlers = [[getPipelineDetailsQuery, successHandler]];

  const defaultProvideOptions = {
    pipelineIid: 1,
    paths: {
      pipelinesPath: '/namespace/my-project/-/pipelines',
      fullProject: '/namespace/my-project',
    },
  };

  const defaultProps = {
    yamlErrors: '',
    trigger: false,
  };

  const createMockApolloProvider = (handlers) => {
    return createMockApollo(handlers);
  };

  const createComponent = (handlers = defaultHandlers, props = defaultProps) => {
    glModalDirective = jest.fn();

    wrapper = shallowMountExtended(PipelineDetailsHeader, {
      provide: {
        ...defaultProvideOptions,
      },
      propsData: {
        ...props,
      },
      directives: {
        glModal: {
          bind(_, { value }) {
            glModalDirective(value);
          },
        },
      },
      stubs: { GlSprintf },
      apolloProvider: createMockApolloProvider(handlers),
    });
  };

  describe('loading state', () => {
    it('shows a loading state while graphQL is fetching initial data', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('defaults', () => {
    beforeEach(async () => {
      createComponent();

      await waitForPromises();
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
      expect(findTotalJobs().text()).toBe('3 Jobs');
    });

    it('has link to commit', () => {
      const {
        data: {
          project: { pipeline },
        },
      } = pipelineHeaderSuccess;

      expect(findCommitLink().attributes('href')).toBe(pipeline.commit.webPath);
    });

    it('displays correct badges', () => {
      expect(findAllBadges()).toHaveLength(2);
      expect(wrapper.findByText('merged results').exists()).toBe(true);
      expect(wrapper.findByText('Scheduled').exists()).toBe(true);
      expect(wrapper.findByText('trigger token').exists()).toBe(false);
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

  describe('with triggered pipeline', () => {
    beforeEach(async () => {
      createComponent(defaultHandlers, {
        ...defaultProps,
        trigger: true,
      });

      await waitForPromises();
    });

    it('displays triggered badge', () => {
      expect(wrapper.findByText('trigger token').exists()).toBe(true);
    });
  });

  describe('without pipeline name', () => {
    it('displays commit title', async () => {
      createComponent([[getPipelineDetailsQuery, runningHandler]]);

      await waitForPromises();

      const expectedTitle = pipelineHeaderSuccess.data.project.pipeline.commit.title;

      expect(findPipelineName().exists()).toBe(false);
      expect(findCommitTitle().text()).toBe(expectedTitle);
    });
  });

  describe('finished pipeline', () => {
    it('does not display created time ago', async () => {
      createComponent();

      await waitForPromises();

      expect(findCreatedTimeAgo().exists()).toBe(false);
    });

    it('displays finished time ago', async () => {
      createComponent();

      await waitForPromises();

      expect(findFinishedTimeAgo().exists()).toBe(true);
    });

    it('displays pipeline duartion text', async () => {
      createComponent();

      await waitForPromises();

      expect(findPipelineDuration().text()).toBe(
        '120 minutes 10 seconds, queued for 3,600 seconds',
      );
    });
  });

  describe('running pipeline', () => {
    beforeEach(async () => {
      createComponent([[getPipelineDetailsQuery, runningHandler]]);

      await waitForPromises();
    });

    it('does not display finished time ago', () => {
      expect(findFinishedTimeAgo().exists()).toBe(false);
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
    beforeEach(async () => {
      createComponent([[getPipelineDetailsQuery, runningHandlerWithDuration]]);

      await waitForPromises();
    });

    it('does not display pipeline duration text', () => {
      expect(findPipelineDuration().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    describe('retry action', () => {
      beforeEach(async () => {
        createComponent([
          [getPipelineDetailsQuery, failedHandler],
          [retryPipelineMutation, retryMutationHandlerSuccess],
        ]);

        await waitForPromises();
      });

      it('should call retryPipeline Mutation with pipeline id', () => {
        findRetryButton().vm.$emit('click');

        expect(retryMutationHandlerSuccess).toHaveBeenCalledWith({
          id: pipelineHeaderFailed.data.project.pipeline.id,
        });
        expect(findAlert().exists()).toBe(false);
      });

      it('should render retry action tooltip', () => {
        expect(findRetryButton().attributes('title')).toBe(BUTTON_TOOLTIP_RETRY);
      });
    });

    describe('retry action failed', () => {
      beforeEach(async () => {
        createComponent([
          [getPipelineDetailsQuery, failedHandler],
          [retryPipelineMutation, retryMutationHandlerFailed],
        ]);

        await waitForPromises();
      });

      it('should display error message on failure', async () => {
        findRetryButton().vm.$emit('click');

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });

      it('retry button loading state should reset on error', async () => {
        findRetryButton().vm.$emit('click');

        await nextTick();

        expect(findRetryButton().props('loading')).toBe(true);

        await waitForPromises();

        expect(findRetryButton().props('loading')).toBe(false);
      });
    });

    describe('cancel action', () => {
      describe('with permissions', () => {
        it('should call cancelPipeline Mutation with pipeline id', async () => {
          createComponent([
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerSuccess],
          ]);

          await waitForPromises();

          findCancelButton().vm.$emit('click');

          expect(cancelMutationHandlerSuccess).toHaveBeenCalledWith({
            id: pipelineHeaderRunning.data.project.pipeline.id,
          });
          expect(findAlert().exists()).toBe(false);
        });

        it('should render cancel action tooltip', async () => {
          createComponent([
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerSuccess],
          ]);

          await waitForPromises();

          expect(findCancelButton().attributes('title')).toBe(BUTTON_TOOLTIP_CANCEL);
        });

        it('should display error message on failure', async () => {
          createComponent([
            [getPipelineDetailsQuery, runningHandler],
            [cancelPipelineMutation, cancelMutationHandlerFailed],
          ]);

          await waitForPromises();

          findCancelButton().vm.$emit('click');

          await waitForPromises();

          expect(findAlert().exists()).toBe(true);
        });
      });

      describe('without permissions', () => {
        it('should not display cancel pipeline button', async () => {
          createComponent([[getPipelineDetailsQuery, runningHandlerNoPermissions]]);

          await waitForPromises();

          expect(findCancelButton().exists()).toBe(false);
        });
      });
    });

    describe('delete action', () => {
      it('displays delete modal when clicking on delete and does not call the delete action', async () => {
        createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerSuccess],
        ]);

        await waitForPromises();

        findDeleteButton().vm.$emit('click');

        const modalId = 'pipeline-delete-modal';

        expect(findDeleteModal().props('modalId')).toBe(modalId);
        expect(glModalDirective).toHaveBeenCalledWith(modalId);
        expect(deleteMutationHandlerSuccess).not.toHaveBeenCalled();
        expect(findAlert().exists()).toBe(false);
      });

      it('should call deletePipeline Mutation with pipeline id when modal is submitted', async () => {
        createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerSuccess],
        ]);

        await waitForPromises();

        findDeleteModal().vm.$emit('primary');

        expect(deleteMutationHandlerSuccess).toHaveBeenCalledWith({
          id: pipelineHeaderSuccess.data.project.pipeline.id,
        });
      });

      it('should display error message on failure', async () => {
        createComponent([
          [getPipelineDetailsQuery, successHandler],
          [deletePipelineMutation, deleteMutationHandlerFailed],
        ]);

        await waitForPromises();

        findDeleteModal().vm.$emit('primary');

        await waitForPromises();

        expect(findAlert().exists()).toBe(true);
      });
    });
  });
});

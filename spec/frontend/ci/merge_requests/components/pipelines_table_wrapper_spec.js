import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import Api from '~/api';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesTableWrapper from '~/ci/merge_requests/components/pipelines_table_wrapper.vue';
import { MR_PIPELINE_TYPE_DETACHED } from '~/ci/merge_requests/constants';
import getMergeRequestsPipelines from '~/ci/merge_requests/graphql/queries/get_merge_request_pipelines.query.graphql';
import cancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import retryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import { generateMRPipelinesResponse } from '../mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

const $toast = {
  show: jest.fn(),
};

let wrapper;
let mergeRequestPipelinesRequest;
let cancelPipelineMutationRequest;
let retryPipelineMutationRequest;
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

const createComponent = ({ mountFn = shallowMountExtended, props = {} } = {}) => {
  const handlers = [
    [getMergeRequestsPipelines, mergeRequestPipelinesRequest],
    [cancelPipelineMutation, cancelPipelineMutationRequest],
    [retryPipelineMutation, retryPipelineMutationRequest],
  ];

  apolloMock = createMockApollo(handlers);

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
const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');

beforeEach(() => {
  mergeRequestPipelinesRequest = jest.fn();
  mergeRequestPipelinesRequest.mockResolvedValue(generateMRPipelinesResponse({ count: 1 }));

  cancelPipelineMutationRequest = jest.fn();
  cancelPipelineMutationRequest.mockResolvedValue({ data: { pipelineCancel: { errors: [] } } });

  retryPipelineMutationRequest = jest.fn();
  retryPipelineMutationRequest.mockResolvedValue({ data: { pipelineRetry: { errors: [] } } });
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
          '/help/user/permissions.md#cicd',
        );

        expect(findEmptyState().text()).toContain('To run a merge request pipeline');
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
    beforeEach(async () => {
      await createComponent();
    });

    it('polls every 10 seconds', async () => {
      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(5000);
      await waitForPromises();

      expect(mergeRequestPipelinesRequest).toHaveBeenCalledTimes(2);
    });
  });

  describe('when latest pipeline has detached flag', () => {
    beforeEach(async () => {
      const response = generateMRPipelinesResponse({
        mergeRequestEventType: MR_PIPELINE_TYPE_DETACHED,
      });

      mergeRequestPipelinesRequest.mockResolvedValue(response);

      await createComponent({ mountFn: mountExtended });
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

      describe('success', () => {
        beforeEach(async () => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();
          await createComponent({ mountFn: mountExtended });
          await findRunPipelineBtn().trigger('click');
          await waitForPromises();
        });

        it('displays a toast message during pipeline creation', () => {
          expect($toast.show).toHaveBeenCalledWith('Creating pipeline.');
        });

        it('on desktop, shows a loading button', async () => {
          await findRunPipelineBtn().trigger('click');

          expect(findRunPipelineBtn().props('loading')).toBe(true);

          await waitForPromises();

          expect(findRunPipelineBtn().props('loading')).toBe(false);
        });

        it('on mobile, shows a loading button', async () => {
          await findRunPipelineBtnMobile().trigger('click');

          expect(findRunPipelineBtn().props('loading')).toBe(true);

          await waitForPromises();

          expect(findRunPipelineBtn().props('disabled')).toBe(false);
          expect(findRunPipelineBtn().props('loading')).toBe(false);
        });
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
            { id: 'gid://gitlab/Ci::Pipeline/0' },
          ]);
        });
      });

      describe('When retrying a pipeline', () => {
        it('sends the retry action graphql mutation', async () => {
          expect(retryPipelineMutationRequest.mock.calls).toHaveLength(0);

          findPipelinesList().vm.$emit('retry-pipeline', pipeline);

          await waitForPromises();

          expect(retryPipelineMutationRequest.mock.calls[0]).toEqual([
            { id: 'gid://gitlab/Ci::Pipeline/0' },
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
});

import { GlLoadingIcon, GlModal, GlTableLite } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { nextTick } from 'vue';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import PipelinesTable from '~/commit/pipelines/pipelines_table.vue';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import { createAlert } from '~/flash';
import { TOAST_MESSAGE } from '~/pipelines/constants';
import axios from '~/lib/utils/axios_utils';

const $toast = {
  show: jest.fn(),
};

jest.mock('~/flash');

describe('Pipelines table in Commits and Merge requests', () => {
  let wrapper;
  let pipeline;
  let mock;

  const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
  const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorEmptyState = () => wrapper.findByTestId('pipeline-error-empty-state');
  const findEmptyState = () => wrapper.findByTestId('pipeline-empty-state');
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findModal = () => wrapper.findComponent(GlModal);
  const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: {
          endpoint: 'endpoint.json',
          emptyStateSvgPath: 'foo',
          errorStateSvgPath: 'foo',
          ...props,
        },
        mocks: {
          $toast,
        },
      }),
    );
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    const { pipelines } = fixture;

    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(200, []);

        createComponent();

        await waitForPromises();
      });

      it('should render the empty state', () => {
        expect(findTableRows()).toHaveLength(0);
        expect(findLoadingState().exists()).toBe(false);
        expect(findErrorEmptyState().exists()).toBe(false);
        expect(findEmptyState().exists()).toBe(true);
      });

      it('should render correct empty state content', () => {
        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findMrPipelinesDocsLink().attributes('href')).toBe(
          '/help/ci/pipelines/merge_request_pipelines.md#prerequisites',
        );
        expect(findEmptyState().text()).toContain(
          'To run a merge request pipeline, the jobs in the CI/CD configuration file must be configured to run in merge request pipelines.',
        );
      });
    });

    describe('with pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(200, [pipeline], { 'x-total': 10 });

        createComponent();

        await waitForPromises();
      });

      it('should render a table with the received pipelines', () => {
        expect(findTable().exists()).toBe(true);
        expect(findTableRows()).toHaveLength(1);
        expect(findLoadingState().exists()).toBe(false);
        expect(findErrorEmptyState().exists()).toBe(false);
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', async () => {
          jest.spyOn(wrapper.vm, 'updateContent').mockImplementation(() => {});

          // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
          // eslint-disable-next-line no-restricted-syntax
          await wrapper.setData({
            store: {
              state: {
                pageInfo: {
                  page: 1,
                  total: 10,
                  perPage: 2,
                  nextPage: 2,
                  totalPages: 5,
                },
              },
            },
          });

          wrapper.find('.next-page-item').trigger('click');

          expect(wrapper.vm.updateContent).toHaveBeenCalledWith({ page: '2' });
        });
      });

      describe('pipeline badge counts', () => {
        it('should receive update-pipelines-count event', () => {
          const element = document.createElement('div');
          document.body.appendChild(element);

          return new Promise((resolve) => {
            element.addEventListener('update-pipelines-count', (event) => {
              expect(event.detail.pipelineCount).toEqual(10);
              resolve();
            });

            createComponent();

            element.appendChild(wrapper.vm.$el);
          });
        });
      });
    });
  });

  describe('run pipeline button', () => {
    let pipelineCopy;

    beforeEach(() => {
      pipelineCopy = { ...pipeline };
    });

    describe('when latest pipeline has detached flag', () => {
      it('renders the run pipeline button', async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;
        pipelineCopy.flags.merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        createComponent();

        await waitForPromises();

        expect(findRunPipelineBtn().exists()).toBe(true);
        expect(findRunPipelineBtnMobile().exists()).toBe(true);
      });
    });

    describe('when latest pipeline does not have detached flag', () => {
      it('does not render the run pipeline button', async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = false;
        pipelineCopy.flags.merge_request_pipeline = false;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        createComponent();

        await waitForPromises();

        expect(findRunPipelineBtn().exists()).toBe(false);
        expect(findRunPipelineBtnMobile().exists()).toBe(false);
      });
    });

    describe('on click', () => {
      beforeEach(async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        createComponent({
          canRunPipeline: true,
          projectId: '5',
          mergeRequestId: 3,
        });

        await waitForPromises();
      });
      describe('success', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockReturnValue(Promise.resolve());
        });
        it('displays a toast message during pipeline creation', async () => {
          await findRunPipelineBtn().trigger('click');

          expect($toast.show).toHaveBeenCalledWith(TOAST_MESSAGE);
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

          jest
            .spyOn(Api, 'postMergeRequestPipeline')
            .mockImplementation(() => Promise.reject(response));

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
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(200, [pipelineCopy]);

        createComponent({
          projectId: '5',
          mergeRequestId: 3,
          canCreatePipelineInTargetProject: true,
          sourceProjectFullPath: 'test/parent-project',
          targetProjectFullPath: 'test/fork-project',
        });

        jest.spyOn(Api, 'postMergeRequestPipeline').mockReturnValue(Promise.resolve());

        await waitForPromises();
      });

      it('on desktop, shows a security warning modal', async () => {
        await findRunPipelineBtn().trigger('click');

        await nextTick();

        expect(findModal()).not.toBeNull();
      });

      it('on mobile, shows a security warning modal', async () => {
        await findRunPipelineBtnMobile().trigger('click');

        expect(findModal()).not.toBeNull();
      });
    });

    describe('when no pipelines were created on a forked merge request', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(200, []);

        createComponent({
          projectId: '5',
          mergeRequestId: 3,
          canCreatePipelineInTargetProject: true,
          sourceProjectFullPath: 'test/parent-project',
          targetProjectFullPath: 'test/fork-project',
        });

        jest.spyOn(findModal().vm, 'show').mockReturnValue();

        await waitForPromises();
      });

      it('should show security modal from empty state run pipeline button', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findModal().exists()).toBe(true);

        findRunPipelineBtn().trigger('click');

        expect(findModal().vm.show).toHaveBeenCalled();
      });
    });
  });

  describe('unsuccessfull request', () => {
    beforeEach(async () => {
      mock.onGet('endpoint.json').reply(500, []);

      createComponent();

      await waitForPromises();
    });

    it('should render error state', () => {
      expect(findErrorEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
    });
  });
});

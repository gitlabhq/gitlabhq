import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlModal, GlTableLite } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import fixture from 'test_fixtures/pipelines/pipelines.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import LegacyPipelinesTableWrapper from '~/commit/pipelines/legacy_pipelines_table_wrapper.vue';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import {
  HTTP_STATUS_BAD_REQUEST,
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_OK,
  HTTP_STATUS_UNAUTHORIZED,
} from '~/lib/utils/http_status';
import { createAlert } from '~/alert';
import { TOAST_MESSAGE } from '~/ci/pipeline_details/constants';
import axios from '~/lib/utils/axios_utils';

Vue.use(VueApollo);

const $toast = {
  show: jest.fn(),
};

jest.mock('~/alert');

describe('Pipelines table in Commits and Merge requests', () => {
  let wrapper;
  let pipeline;
  let mock;
  const showMock = jest.fn();

  const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
  const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findErrorEmptyState = () => wrapper.findByTestId('pipeline-error-empty-state');
  const findEmptyState = () => wrapper.findByTestId('pipeline-empty-state');
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findModal = () => wrapper.findComponent(GlModal);
  const findMrPipelinesDocsLink = () => wrapper.findByTestId('mr-pipelines-docs-link');
  const findUserPermissionsDocsLink = () => wrapper.findByTestId('user-permissions-docs-link');
  const findPipelinesTable = () => wrapper.findComponent(PipelinesTable);

  const createComponent = ({ props = {}, mountFn = mountExtended } = {}) => {
    wrapper = mountFn(LegacyPipelinesTableWrapper, {
      propsData: {
        endpoint: 'endpoint.json',
        emptyStateSvgPath: 'foo',
        errorStateSvgPath: 'foo',
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
      apolloProvider: createMockApollo(),
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    const { pipelines } = fixture;

    pipeline = pipelines.find((p) => p.user !== null && p.commit !== null);
  });

  describe('successful request', () => {
    describe('without pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, []);

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
        expect(findUserPermissionsDocsLink().attributes('href')).toBe(
          '/help/user/permissions.md#cicd',
        );
        expect(findEmptyState().text()).toContain(
          'To run a merge request pipeline, the jobs in the CI/CD configuration file must be configured to run in merge request pipelines ' +
            'and you must have sufficient permissions in the source project.',
        );
      });
    });

    describe('with pagination', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline], {
          'X-TOTAL': 10,
          'X-PER-PAGE': 2,
          'X-PAGE': 1,
          'X-TOTAL-PAGES': 5,
          'X-NEXT-PAGE': 2,
          'X-PREV-PAGE': 2,
        });

        createComponent();

        await waitForPromises();
      });

      it('should make an API request when using pagination', async () => {
        expect(mock.history.get).toHaveLength(1);

        wrapper.find('[data-testid="gl-pagination-next"]').trigger('click');

        await waitForPromises();

        expect(mock.history.get).toHaveLength(2);
        expect(mock.history.get[1].params.page).toBe('2');
      });
    });

    describe('with pipelines', () => {
      beforeEach(async () => {
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline], { 'x-total': 10 });

        createComponent();

        await waitForPromises();
      });

      it('should render a table with the received pipelines', () => {
        expect(findTable().exists()).toBe(true);
        expect(findTableRows()).toHaveLength(1);
        expect(findLoadingState().exists()).toBe(false);
        expect(findErrorEmptyState().exists()).toBe(false);
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

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

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

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent();

        await waitForPromises();

        expect(findRunPipelineBtn().exists()).toBe(false);
        expect(findRunPipelineBtnMobile().exists()).toBe(false);
      });
    });

    describe('on click', () => {
      beforeEach(async () => {
        pipelineCopy.flags.detached_merge_request_pipeline = true;

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent({
          props: {
            canRunPipeline: true,
            projectId: '5',
            mergeRequestId: 3,
          },
        });

        await waitForPromises();
      });

      describe('success', () => {
        beforeEach(() => {
          jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();
        });

        describe('when the table is a merge request table', () => {
          beforeEach(async () => {
            createComponent({
              props: {
                canRunPipeline: true,
                isMergeRequestTable: true,
                mergeRequestId: 3,
                projectId: '5',
              },
            });

            await waitForPromises();
          });

          it('on desktop, shows a loading button', async () => {
            await findRunPipelineBtn().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);
          });

          it('on mobile, shows a loading button', async () => {
            await findRunPipelineBtnMobile().trigger('click');

            expect(findRunPipelineBtn().props('loading')).toBe(true);

            await waitForPromises();

            expect(findRunPipelineBtn().props('disabled')).toBe(false);
          });

          it('sets isCreatingPipeline to true in pipelines table', async () => {
            expect(findPipelinesTable().props('isCreatingPipeline')).toBe(false);

            await findRunPipelineBtn().trigger('click');

            expect(findPipelinesTable().props('isCreatingPipeline')).toBe(true);
          });
        });

        describe('when the table is not a merge request table', () => {
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

        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipelineCopy]);

        createComponent({
          props: {
            projectId: '5',
            mergeRequestId: 3,
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });

        jest.spyOn(Api, 'postMergeRequestPipeline').mockResolvedValue();

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
        mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, []);

        createComponent({
          props: {
            projectId: '5',
            mergeRequestId: 3,
            canCreatePipelineInTargetProject: true,
            sourceProjectFullPath: 'test/parent-project',
            targetProjectFullPath: 'test/fork-project',
          },
        });

        await waitForPromises();
      });

      it('should show security modal from empty state run pipeline button', () => {
        expect(findEmptyState().exists()).toBe(true);
        expect(findModal().exists()).toBe(true);

        findRunPipelineBtn().trigger('click');

        expect(showMock).toHaveBeenCalled();
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(async () => {
      mock.onGet('endpoint.json').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, []);

      createComponent();

      await waitForPromises();
    });

    it('should render error state', () => {
      expect(findErrorEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      mock.onGet('endpoint.json').reply(HTTP_STATUS_OK, [pipeline]);

      createComponent({ mountFn: shallowMountExtended });

      await waitForPromises();
    });

    describe('When cancelling a pipeline', () => {
      it('sends the cancel action', async () => {
        expect(mock.history.post).toHaveLength(0);

        findPipelinesTable().vm.$emit('cancel-pipeline', pipeline);

        await waitForPromises();

        expect(mock.history.post).toHaveLength(1);
        expect(mock.history.post[0].url).toContain('cancel.json');
      });
    });

    describe('When retrying a pipeline', () => {
      it('sends the retry action', async () => {
        expect(mock.history.post).toHaveLength(0);

        findPipelinesTable().vm.$emit('retry-pipeline', pipeline);

        await waitForPromises();

        expect(mock.history.post).toHaveLength(1);
        expect(mock.history.post[0].url).toContain('retry.json');
      });
    });

    describe('When refreshing a pipeline', () => {
      it('calls the pipelines endpoint again', async () => {
        expect(mock.history.get).toHaveLength(1);

        findPipelinesTable().vm.$emit('refresh-pipelines-table');

        await waitForPromises();

        expect(mock.history.get).toHaveLength(2);
        expect(mock.history.get[1].url).toContain('endpoint.json');
      });
    });
  });
});

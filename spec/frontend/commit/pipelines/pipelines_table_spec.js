import { GlEmptyState, GlLoadingIcon, GlModal, GlTable } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import PipelinesTable from '~/commit/pipelines/pipelines_table.vue';
import axios from '~/lib/utils/axios_utils';

describe('Pipelines table in Commits and Merge requests', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';
  let wrapper;
  let pipeline;
  let mock;

  const findRunPipelineBtn = () => wrapper.findByTestId('run_pipeline_button');
  const findRunPipelineBtnMobile = () => wrapper.findByTestId('run_pipeline_button_mobile');
  const findLoadingState = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRows = () => wrapper.findAllByTestId('pipeline-table-row');
  const findModal = () => wrapper.findComponent(GlModal);

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      mount(PipelinesTable, {
        propsData: {
          endpoint: 'endpoint.json',
          emptyStateSvgPath: 'foo',
          errorStateSvgPath: 'foo',
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);

    const { pipelines } = getJSONFixture(jsonFixtureName);

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
        expect(findEmptyState().exists()).toBe(false);
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
        expect(findEmptyState().exists()).toBe(false);
      });

      describe('with pagination', () => {
        it('should make an API request when using pagination', async () => {
          jest.spyOn(wrapper.vm, 'updateContent').mockImplementation(() => {});

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
        it('should receive update-pipelines-count event', (done) => {
          const element = document.createElement('div');
          document.body.appendChild(element);

          element.addEventListener('update-pipelines-count', (event) => {
            expect(event.detail.pipelineCount).toEqual(10);
            done();
          });

          createComponent();

          element.appendChild(wrapper.vm.$el);
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

        jest.spyOn(Api, 'postMergeRequestPipeline').mockReturnValue(Promise.resolve());

        await waitForPromises();
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

        await wrapper.vm.$nextTick();

        expect(findModal()).not.toBeNull();
      });

      it('on mobile, shows a security warning modal', async () => {
        await findRunPipelineBtnMobile().trigger('click');

        expect(findModal()).not.toBeNull();
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
      expect(findEmptyState().text()).toBe(
        'There was an error fetching the pipelines. Try again in a few moments or contact your support team.',
      );
    });
  });
});

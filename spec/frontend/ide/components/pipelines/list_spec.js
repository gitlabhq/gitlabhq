import { GlLoadingIcon, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import { pipelines } from 'jest/ide/mock_data';
import JobsList from '~/ide/components/jobs/list.vue';
import List from '~/ide/components/pipelines/list.vue';
import IDEServices from '~/ide/services';
import CiIcon from '~/vue_shared/components/ci_icon.vue';

Vue.use(Vuex);

jest.mock('~/ide/services', () => ({
  pingUsage: jest.fn(),
}));

describe('IDE pipelines list', () => {
  let wrapper;

  const defaultState = {
    pipelinesEmptyStateSvgPath: TEST_HOST,
  };
  const defaultPipelinesState = {
    stages: [],
    failedStages: [],
    isLoadingJobs: false,
  };

  const fetchLatestPipelineMock = jest.fn();
  const pingUsageMock = jest.fn();
  const failedStagesGetterMock = jest.fn().mockReturnValue([]);
  const fakeProjectPath = 'alpha/beta';

  const createStore = (rootState, pipelinesState) => {
    return new Vuex.Store({
      getters: {
        currentProject: () => ({ web_url: 'some/url ', path_with_namespace: fakeProjectPath }),
      },
      state: {
        ...defaultState,
        ...rootState,
      },
      modules: {
        pipelines: {
          namespaced: true,
          state: {
            ...defaultPipelinesState,
            ...pipelinesState,
          },
          actions: {
            fetchLatestPipeline: fetchLatestPipelineMock,
            pingUsage: pingUsageMock,
          },
          getters: {
            jobsCount: () => 1,
            failedJobsCount: () => 1,
            failedStages: failedStagesGetterMock,
            pipelineFailed: () => false,
          },
        },
      },
    });
  };

  const createComponent = (state = {}, pipelinesState = {}) => {
    wrapper = shallowMount(List, {
      store: createStore(state, pipelinesState),
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('fetches latest pipeline', () => {
    createComponent();

    expect(fetchLatestPipelineMock).toHaveBeenCalled();
  });

  it('pings pipeline usage', () => {
    createComponent();
    expect(IDEServices.pingUsage).toHaveBeenCalledWith(fakeProjectPath);
  });

  describe('when loading', () => {
    let defaultPipelinesLoadingState;

    beforeAll(() => {
      defaultPipelinesLoadingState = {
        isLoadingPipeline: true,
      };
    });

    it('does not render when pipeline has loaded before', () => {
      createComponent(
        {},
        {
          ...defaultPipelinesLoadingState,
          hasLoadedPipeline: true,
        },
      );

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    });

    it('renders loading state', () => {
      createComponent(
        {},
        {
          ...defaultPipelinesLoadingState,
          hasLoadedPipeline: false,
        },
      );

      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when loaded', () => {
    let defaultPipelinesLoadedState;

    beforeAll(() => {
      defaultPipelinesLoadedState = {
        isLoadingPipeline: false,
        hasLoadedPipeline: true,
      };
    });

    it('renders empty state when no latestPipeline', () => {
      createComponent({}, { ...defaultPipelinesLoadedState, latestPipeline: null });
      expect(wrapper.element).toMatchSnapshot();
    });

    describe('with latest pipeline loaded', () => {
      let withLatestPipelineState;

      beforeAll(() => {
        withLatestPipelineState = {
          ...defaultPipelinesLoadedState,
          latestPipeline: pipelines[0],
        };
      });

      it('renders ci icon', () => {
        createComponent({}, withLatestPipelineState);
        expect(wrapper.find(CiIcon).exists()).toBe(true);
      });

      it('renders pipeline data', () => {
        createComponent({}, withLatestPipelineState);

        expect(wrapper.text()).toContain('#1');
      });

      it('renders list of jobs', () => {
        const stages = [];
        const isLoadingJobs = true;
        createComponent({}, { ...withLatestPipelineState, stages, isLoadingJobs });

        const jobProps = wrapper.findAll(GlTab).at(0).find(JobsList).props();
        expect(jobProps.stages).toBe(stages);
        expect(jobProps.loading).toBe(isLoadingJobs);
      });

      it('renders list of failed jobs', () => {
        const failedStages = [];
        failedStagesGetterMock.mockReset().mockReturnValue(failedStages);
        const isLoadingJobs = true;
        createComponent({}, { ...withLatestPipelineState, isLoadingJobs });

        const jobProps = wrapper.findAll(GlTab).at(1).find(JobsList).props();
        expect(jobProps.stages).toBe(failedStages);
        expect(jobProps.loading).toBe(isLoadingJobs);
      });

      describe('with YAML error', () => {
        it('renders YAML error', () => {
          const yamlError = 'test yaml error';
          createComponent(
            {},
            {
              ...defaultPipelinesLoadedState,
              latestPipeline: { ...pipelines[0], yamlError },
            },
          );

          expect(wrapper.text()).toContain('Found errors in your .gitlab-ci.yml:');
          expect(wrapper.text()).toContain(yamlError);
        });
      });
    });
  });
});

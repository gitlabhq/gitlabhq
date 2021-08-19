import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import getUserCallouts from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import axios from '~/lib/utils/axios_utils';
import {
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';
import * as perfUtils from '~/performance/utils';
import {
  IID_FAILURE,
  LAYER_VIEW,
  STAGE_VIEW,
  VIEW_TYPE_KEY,
} from '~/pipelines/components/graph/constants';
import PipelineGraph from '~/pipelines/components/graph/graph_component.vue';
import PipelineGraphWrapper from '~/pipelines/components/graph/graph_component_wrapper.vue';
import GraphViewSelector from '~/pipelines/components/graph/graph_view_selector.vue';
import StageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';
import * as Api from '~/pipelines/components/graph_shared/api';
import LinksLayer from '~/pipelines/components/graph_shared/links_layer.vue';
import * as parsingUtils from '~/pipelines/components/parsing_utils';
import getPipelineHeaderData from '~/pipelines/graphql/queries/get_pipeline_header_data.query.graphql';
import * as sentryUtils from '~/pipelines/utils';
import { mockRunningPipelineHeaderData } from '../mock_data';
import { mapCallouts, mockCalloutsResponse, mockPipelineResponse } from './mock_data';

const defaultProvide = {
  graphqlResourceEtag: 'frog/amphibirama/etag/',
  metricsPath: '',
  pipelineProjectPath: 'frog/amphibirama',
  pipelineIid: '22',
};

describe('Pipeline graph wrapper', () => {
  Vue.use(VueApollo);
  useLocalStorageSpy();

  let wrapper;
  const getAlert = () => wrapper.findComponent(GlAlert);
  const getDependenciesToggle = () => wrapper.find('[data-testid="show-links-toggle"]');
  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const getLinksLayer = () => wrapper.findComponent(LinksLayer);
  const getGraph = () => wrapper.find(PipelineGraph);
  const getStageColumnTitle = () => wrapper.find('[data-testid="stage-column-title"]');
  const getAllStageColumnGroupsInColumn = () =>
    wrapper.find(StageColumnComponent).findAll('[data-testid="stage-column-group"]');
  const getViewSelector = () => wrapper.find(GraphViewSelector);
  const getViewSelectorTrip = () => getViewSelector().findComponent(GlAlert);

  const createComponent = ({
    apolloProvider,
    data = {},
    provide = {},
    mountFn = shallowMount,
  } = {}) => {
    wrapper = mountFn(PipelineGraphWrapper, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      apolloProvider,
      data() {
        return {
          ...data,
        };
      },
    });
  };

  const createComponentWithApollo = ({
    calloutsList = [],
    data = {},
    getPipelineDetailsHandler = jest.fn().mockResolvedValue(mockPipelineResponse),
    mountFn = shallowMount,
    provide = {},
  } = {}) => {
    const callouts = mapCallouts(calloutsList);
    const getUserCalloutsHandler = jest.fn().mockResolvedValue(mockCalloutsResponse(callouts));
    const getPipelineHeaderDataHandler = jest.fn().mockResolvedValue(mockRunningPipelineHeaderData);

    const requestHandlers = [
      [getPipelineHeaderData, getPipelineHeaderDataHandler],
      [getPipelineDetails, getPipelineDetailsHandler],
      [getUserCallouts, getUserCalloutsHandler],
    ];

    const apolloProvider = createMockApollo(requestHandlers);
    createComponent({ apolloProvider, data, provide, mountFn });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  beforeAll(() => {
    jest.useFakeTimers();
  });

  afterAll(() => {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  });

  describe('when data is loading', () => {
    it('displays the loading icon', () => {
      createComponentWithApollo();
      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('does not display the alert', () => {
      createComponentWithApollo();
      expect(getAlert().exists()).toBe(false);
    });

    it('does not display the graph', () => {
      createComponentWithApollo();
      expect(getGraph().exists()).toBe(false);
    });

    it('skips querying headerPipeline', () => {
      createComponentWithApollo();
      expect(wrapper.vm.$apollo.queries.headerPipeline.skip).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
    });

    it('does not display the loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('does not display the alert', () => {
      expect(getAlert().exists()).toBe(false);
    });

    it('displays the graph', () => {
      expect(getGraph().exists()).toBe(true);
    });

    it('passes the etag resource and metrics path to the graph', () => {
      expect(getGraph().props('configPaths')).toMatchObject({
        graphqlResourceEtag: defaultProvide.graphqlResourceEtag,
        metricsPath: defaultProvide.metricsPath,
      });
    });
  });

  describe('when there is an error', () => {
    beforeEach(async () => {
      createComponentWithApollo({
        getPipelineDetailsHandler: jest.fn().mockRejectedValue(new Error('GraphQL error')),
      });
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
    });

    it('does not display the loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('displays the alert', () => {
      expect(getAlert().exists()).toBe(true);
    });

    it('does not display the graph', () => {
      expect(getGraph().exists()).toBe(false);
    });
  });

  describe('when there is no pipeline iid available', () => {
    beforeEach(async () => {
      createComponentWithApollo({
        provide: {
          pipelineIid: '',
        },
      });
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
    });

    it('does not display the loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('displays the no iid alert', () => {
      expect(getAlert().exists()).toBe(true);
      expect(getAlert().text()).toBe(wrapper.vm.$options.errorTexts[IID_FAILURE]);
    });

    it('does not display the graph', () => {
      expect(getGraph().exists()).toBe(false);
    });
  });

  describe('when refresh action is emitted', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      jest.spyOn(wrapper.vm.$apollo.queries.headerPipeline, 'refetch');
      jest.spyOn(wrapper.vm.$apollo.queries.pipeline, 'refetch');
      await wrapper.vm.$nextTick();
      getGraph().vm.$emit('refreshPipelineGraph');
    });

    it('calls refetch', () => {
      expect(wrapper.vm.$apollo.queries.headerPipeline.skip).toBe(false);
      expect(wrapper.vm.$apollo.queries.headerPipeline.refetch).toHaveBeenCalled();
      expect(wrapper.vm.$apollo.queries.pipeline.refetch).toHaveBeenCalled();
    });
  });

  describe('when query times out', () => {
    const advanceApolloTimers = async () => {
      jest.runOnlyPendingTimers();
      await wrapper.vm.$nextTick();
      await wrapper.vm.$nextTick();
    };

    beforeEach(async () => {
      const errorData = {
        data: {
          project: {
            pipelines: null,
          },
        },
        errors: [{ message: 'timeout' }],
      };

      const failSucceedFail = jest
        .fn()
        .mockResolvedValueOnce(errorData)
        .mockResolvedValueOnce(mockPipelineResponse)
        .mockResolvedValueOnce(errorData);

      createComponentWithApollo({ getPipelineDetailsHandler: failSucceedFail });
      await wrapper.vm.$nextTick();
    });

    it('shows correct errors and does not overwrite populated data when data is empty', async () => {
      /* fails at first, shows error, no data yet */
      expect(getAlert().exists()).toBe(true);
      expect(getGraph().exists()).toBe(false);

      /* succeeds, clears error, shows graph */
      await advanceApolloTimers();
      expect(getAlert().exists()).toBe(false);
      expect(getGraph().exists()).toBe(true);

      /* fails again, alert returns but data persists */
      await advanceApolloTimers();
      expect(getAlert().exists()).toBe(true);
      expect(getGraph().exists()).toBe(true);
    });
  });

  describe('view dropdown', () => {
    describe('default', () => {
      let layersFn;
      beforeEach(async () => {
        layersFn = jest.spyOn(parsingUtils, 'listByLayers');
        createComponentWithApollo({
          mountFn: mount,
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('appears when pipeline uses needs', () => {
        expect(getViewSelector().exists()).toBe(true);
      });

      it('switches between views', async () => {
        const groupsInFirstColumn =
          mockPipelineResponse.data.project.pipeline.stages.nodes[0].groups.nodes.length;
        expect(getAllStageColumnGroupsInColumn()).toHaveLength(groupsInFirstColumn);
        expect(getStageColumnTitle().text()).toBe('Build');
        await getViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        expect(getAllStageColumnGroupsInColumn()).toHaveLength(groupsInFirstColumn + 1);
        expect(getStageColumnTitle().text()).toBe('');
      });

      it('saves the view type to local storage', async () => {
        await getViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        expect(localStorage.setItem.mock.calls).toEqual([[VIEW_TYPE_KEY, LAYER_VIEW]]);
      });

      it('calls listByLayers only once no matter how many times view is switched', async () => {
        expect(layersFn).not.toHaveBeenCalled();
        await getViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        expect(layersFn).toHaveBeenCalledTimes(1);
        await getViewSelector().vm.$emit('updateViewType', STAGE_VIEW);
        await getViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        await getViewSelector().vm.$emit('updateViewType', STAGE_VIEW);
        expect(layersFn).toHaveBeenCalledTimes(1);
      });
    });

    describe('when layers view is selected', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          data: {
            currentViewType: LAYER_VIEW,
          },
          mountFn: mount,
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('sets showLinks to true', async () => {
        /* This spec uses .props for performance reasons. */
        expect(getLinksLayer().exists()).toBe(true);
        expect(getLinksLayer().props('showLinks')).toBe(false);
        expect(getViewSelector().props('type')).toBe(LAYER_VIEW);
        await getDependenciesToggle().trigger('click');
        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
        expect(wrapper.findComponent(LinksLayer).props('showLinks')).toBe(true);
      });
    });

    describe('when layers view is selected, and links are active', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          data: {
            currentViewType: LAYER_VIEW,
            showLinks: true,
          },
          mountFn: mount,
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('shows the hover tip in the view selector', async () => {
        await getViewSelector().setData({ showLinksActive: true });
        expect(getViewSelectorTrip().exists()).toBe(true);
      });
    });

    describe('when hover tip would otherwise show, but it has been previously dismissed', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          data: {
            currentViewType: LAYER_VIEW,
            showLinks: true,
          },
          mountFn: mount,
          calloutsList: ['pipeline_needs_hover_tip'.toUpperCase()],
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('does not show the hover tip', async () => {
        await getViewSelector().setData({ showLinksActive: true });
        expect(getViewSelectorTrip().exists()).toBe(false);
      });
    });

    describe('when feature flag is on and local storage is set', () => {
      beforeEach(async () => {
        localStorage.setItem(VIEW_TYPE_KEY, LAYER_VIEW);

        createComponentWithApollo({
          mountFn: mount,
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      afterEach(() => {
        localStorage.clear();
      });

      it('reads the view type from localStorage when available', () => {
        const viewSelectorNeedsSegment = wrapper
          .findAll('[data-testid="pipeline-view-selector"] > label')
          .at(1);
        expect(viewSelectorNeedsSegment.classes()).toContain('active');
      });
    });

    describe('when feature flag is on and local storage is set, but the graph does not use needs', () => {
      beforeEach(async () => {
        const nonNeedsResponse = { ...mockPipelineResponse };
        nonNeedsResponse.data.project.pipeline.usesNeeds = false;

        localStorage.setItem(VIEW_TYPE_KEY, LAYER_VIEW);

        createComponentWithApollo({
          mountFn: mount,
          getPipelineDetailsHandler: jest.fn().mockResolvedValue(nonNeedsResponse),
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      afterEach(() => {
        localStorage.clear();
      });

      it('still passes stage type to graph', () => {
        expect(getGraph().props('viewType')).toBe(STAGE_VIEW);
      });
    });

    describe('when feature flag is on but pipeline does not use needs', () => {
      beforeEach(async () => {
        const nonNeedsResponse = { ...mockPipelineResponse };
        nonNeedsResponse.data.project.pipeline.usesNeeds = false;

        createComponentWithApollo({
          mountFn: mount,
          getPipelineDetailsHandler: jest.fn().mockResolvedValue(nonNeedsResponse),
        });

        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('does not appear when pipeline does not use needs', () => {
        expect(getViewSelector().exists()).toBe(false);
      });
    });
  });

  describe('performance metrics', () => {
    const metricsPath = '/root/project/-/ci/prometheus_metrics/histograms.json';
    let markAndMeasure;
    let reportToSentry;
    let reportPerformance;
    let mock;

    beforeEach(() => {
      jest.spyOn(window, 'requestAnimationFrame').mockImplementation((cb) => cb());
      markAndMeasure = jest.spyOn(perfUtils, 'performanceMarkAndMeasure');
      reportToSentry = jest.spyOn(sentryUtils, 'reportToSentry');
      reportPerformance = jest.spyOn(Api, 'reportPerformance');
    });

    describe('with no metrics path', () => {
      beforeEach(async () => {
        createComponentWithApollo();
        jest.runOnlyPendingTimers();
        await wrapper.vm.$nextTick();
      });

      it('is not called', () => {
        expect(markAndMeasure).not.toHaveBeenCalled();
        expect(reportToSentry).not.toHaveBeenCalled();
        expect(reportPerformance).not.toHaveBeenCalled();
      });
    });

    describe('with metrics path', () => {
      const duration = 875;
      const numLinks = 7;
      const totalGroups = 8;
      const metricsData = {
        histograms: [
          { name: PIPELINES_DETAIL_LINK_DURATION, value: duration / 1000 },
          { name: PIPELINES_DETAIL_LINKS_TOTAL, value: numLinks },
          {
            name: PIPELINES_DETAIL_LINKS_JOB_RATIO,
            value: numLinks / totalGroups,
          },
        ],
      };

      describe('when no duration is obtained', () => {
        beforeEach(async () => {
          jest.spyOn(window.performance, 'getEntriesByName').mockImplementation(() => {
            return [];
          });

          createComponentWithApollo({
            provide: {
              metricsPath,
              glFeatures: {
                pipelineGraphLayersView: true,
              },
            },
            data: {
              currentViewType: LAYER_VIEW,
            },
          });

          jest.runOnlyPendingTimers();
          await wrapper.vm.$nextTick();
        });

        it('attempts to collect metrics', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).not.toHaveBeenCalled();
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });

      describe('with duration and no error', () => {
        beforeEach(() => {
          mock = new MockAdapter(axios);
          mock.onPost(metricsPath).reply(200, {});

          jest.spyOn(window.performance, 'getEntriesByName').mockImplementation(() => {
            return [{ duration }];
          });

          createComponentWithApollo({
            provide: {
              metricsPath,
              glFeatures: {
                pipelineGraphLayersView: true,
              },
            },
            data: {
              currentViewType: LAYER_VIEW,
            },
          });
        });

        afterEach(() => {
          mock.restore();
        });

        it('it calls reportPerformance with expected arguments', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalledWith(metricsPath, metricsData);
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });
    });
  });
});

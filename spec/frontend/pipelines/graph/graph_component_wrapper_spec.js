import { GlAlert, GlButton, GlButtonGroup, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import mockPipelineResponse from 'test_fixtures/pipelines/pipeline_details.json';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubPerformanceWebAPI } from 'helpers/performance';
import waitForPromises from 'helpers/wait_for_promises';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import getUserCallouts from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  PIPELINES_DETAIL_LINK_DURATION,
  PIPELINES_DETAIL_LINKS_TOTAL,
  PIPELINES_DETAIL_LINKS_JOB_RATIO,
} from '~/performance/constants';
import * as perfUtils from '~/performance/utils';
import {
  ACTION_FAILURE,
  LAYER_VIEW,
  STAGE_VIEW,
  VIEW_TYPE_KEY,
} from '~/ci/pipeline_details/graph/constants';
import PipelineGraph from '~/ci/pipeline_details/graph/components/graph_component.vue';
import PipelineGraphWrapper from '~/ci/pipeline_details/graph/graph_component_wrapper.vue';
import GraphViewSelector from '~/ci/pipeline_details/graph/components/graph_view_selector.vue';
import * as Api from '~/ci/pipeline_details/graph/api_utils';
import LinksLayer from '~/ci/common/private/job_links_layer.vue';
import * as parsingUtils from '~/ci/pipeline_details/utils/parsing_utils';
import getPipelineHeaderData from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import * as sentryUtils from '~/ci/utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { mockRunningPipelineHeaderData } from '../mock_data';
import {
  mapCallouts,
  mockCalloutsResponse,
  mockPipelineResponseWithTooManyJobs,
} from './mock_data';

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
  let requestHandlers;
  let pipelineDetailsHandler;

  const findAlert = () => wrapper.findByTestId('error-alert');
  const findJobCountWarning = () => wrapper.findByTestId('job-count-warning');
  const findDependenciesToggle = () => wrapper.findByTestId('show-links-toggle');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findLinksLayer = () => wrapper.findComponent(LinksLayer);
  const findGraph = () => wrapper.findComponent(PipelineGraph);
  const findStageColumnTitle = () => wrapper.findByTestId('stage-column-title');
  const findViewSelector = () => wrapper.findComponent(GraphViewSelector);
  const findViewSelectorToggle = () => findViewSelector().findComponent(GlToggle);
  const findViewSelectorTrip = () => findViewSelector().findComponent(GlAlert);
  const getLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);

  const createComponent = ({
    apolloProvider,
    data = {},
    provide = {},
    mountFn = shallowMountExtended,
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
    mountFn = shallowMountExtended,
    provide = {},
  } = {}) => {
    const callouts = mapCallouts(calloutsList);

    requestHandlers = {
      getUserCalloutsHandler: jest.fn().mockResolvedValue(mockCalloutsResponse(callouts)),
      getPipelineHeaderDataHandler: jest.fn().mockResolvedValue(mockRunningPipelineHeaderData),
      getPipelineDetailsHandler: pipelineDetailsHandler,
    };

    const handlers = [
      [getPipelineHeaderData, requestHandlers.getPipelineHeaderDataHandler],
      [getPipelineDetails, requestHandlers.getPipelineDetailsHandler],
      [getUserCallouts, requestHandlers.getUserCalloutsHandler],
    ];

    const apolloProvider = createMockApollo(handlers);
    createComponent({ apolloProvider, data, provide, mountFn });
  };

  beforeEach(() => {
    pipelineDetailsHandler = jest.fn();
    pipelineDetailsHandler.mockResolvedValue(mockPipelineResponse);
  });

  describe('when data is loading', () => {
    beforeEach(() => {
      createComponentWithApollo();
    });

    it('displays the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not display the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('does not display the graph', () => {
      expect(findGraph().exists()).toBe(false);
    });

    it('skips querying headerPipeline', () => {
      expect(wrapper.vm.$apollo.queries.headerPipeline.skip).toBe(true);
    });
  });

  describe('when data has loaded', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await waitForPromises();
    });

    it('does not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('does not display the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('displays the graph', () => {
      expect(findGraph().exists()).toBe(true);
    });

    it('passes the etag resource and metrics path to the graph', () => {
      expect(findGraph().props('configPaths')).toMatchObject({
        graphqlResourceEtag: defaultProvide.graphqlResourceEtag,
        metricsPath: defaultProvide.metricsPath,
      });
    });
  });

  describe('when a stage has 100 jobs or more', () => {
    beforeEach(async () => {
      pipelineDetailsHandler.mockResolvedValue(mockPipelineResponseWithTooManyJobs);
      createComponentWithApollo();
      await waitForPromises();
    });

    it('show a warning alert', () => {
      expect(findJobCountWarning().exists()).toBe(true);
      expect(findJobCountWarning().props().title).toBe(
        'Only the first 100 jobs per stage are displayed',
      );
    });
  });

  describe('when there is an error', () => {
    beforeEach(async () => {
      pipelineDetailsHandler.mockRejectedValue(new Error('GraphQL error'));
      createComponentWithApollo();
      await waitForPromises();
    });

    it('does not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('does not display the graph', () => {
      expect(findGraph().exists()).toBe(false);
    });
  });

  describe('when there is no pipeline iid available', () => {
    beforeEach(async () => {
      createComponentWithApollo({
        provide: {
          pipelineIid: '',
        },
      });
      await waitForPromises();
    });

    it('does not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the no iid alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe(
        'The data in this pipeline is too old to be rendered as a graph. Please check the Jobs tab to access historical data.',
      );
    });

    it('does not display the graph', () => {
      expect(findGraph().exists()).toBe(false);
    });
  });

  describe('events', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await waitForPromises();
    });
    describe('when receiving `setSkipRetryModal` event', () => {
      it('passes down `skipRetryModal` value as true', async () => {
        expect(findGraph().props('skipRetryModal')).toBe(false);

        await findGraph().vm.$emit('setSkipRetryModal');

        expect(findGraph().props('skipRetryModal')).toBe(true);
      });
    });
  });

  describe('when there is an error with an action in the graph', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await waitForPromises();
      await findGraph().vm.$emit('error', { type: ACTION_FAILURE });
    });

    it('does not display the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('displays the action error alert', () => {
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toBe('An error occurred while performing this action.');
    });

    it('displays the graph', () => {
      expect(findGraph().exists()).toBe(true);
    });
  });

  describe('when refresh action is emitted', () => {
    beforeEach(async () => {
      createComponentWithApollo();
      await waitForPromises();
      findGraph().vm.$emit('refreshPipelineGraph');
    });

    it('calls refetch', () => {
      expect(requestHandlers.getPipelineHeaderDataHandler).toHaveBeenCalledWith({
        fullPath: 'frog/amphibirama',
        iid: '22',
      });
      expect(requestHandlers.getPipelineDetailsHandler).toHaveBeenCalledTimes(2);
      expect(requestHandlers.getUserCalloutsHandler).toHaveBeenCalledWith({});
    });
  });

  describe('when query times out', () => {
    const advanceApolloTimers = async () => {
      jest.runOnlyPendingTimers();
      await waitForPromises();
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

      pipelineDetailsHandler
        .mockResolvedValueOnce(errorData)
        .mockResolvedValueOnce(mockPipelineResponse)
        .mockResolvedValueOnce(errorData);

      createComponentWithApollo();
      await waitForPromises();
    });

    it('shows correct errors and does not overwrite populated data when data is empty', async () => {
      /* fails at first, shows error, no data yet */
      expect(findAlert().exists()).toBe(true);
      expect(findGraph().exists()).toBe(false);

      /* succeeds, clears error, shows graph */
      await advanceApolloTimers();
      expect(findAlert().exists()).toBe(false);
      expect(findGraph().exists()).toBe(true);

      /* fails again, alert returns but data persists */
      await advanceApolloTimers();
      expect(findAlert().exists()).toBe(true);
      expect(findGraph().exists()).toBe(true);
    });
  });

  describe('view dropdown', () => {
    describe('default', () => {
      let layersFn;
      beforeEach(async () => {
        layersFn = jest.spyOn(parsingUtils, 'listByLayers');
        createComponentWithApollo({
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      it('appears when pipeline uses needs', () => {
        expect(findViewSelector().exists()).toBe(true);
      });

      it('switches between views', async () => {
        expect(findStageColumnTitle().text()).toBe('deploy');

        await findViewSelector().vm.$emit('updateViewType', LAYER_VIEW);

        expect(findStageColumnTitle().text()).toBe('');
      });

      it('saves the view type to local storage', async () => {
        await findViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        expect(localStorage.setItem.mock.calls).toEqual([[VIEW_TYPE_KEY, LAYER_VIEW]]);
      });

      it('calls listByLayers only once no matter how many times view is switched', async () => {
        expect(layersFn).not.toHaveBeenCalled();
        await findViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        expect(layersFn).toHaveBeenCalledTimes(1);
        await findViewSelector().vm.$emit('updateViewType', STAGE_VIEW);
        await findViewSelector().vm.$emit('updateViewType', LAYER_VIEW);
        await findViewSelector().vm.$emit('updateViewType', STAGE_VIEW);
        expect(layersFn).toHaveBeenCalledTimes(1);
      });
    });

    describe('when layers view is selected', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          data: {
            currentViewType: LAYER_VIEW,
          },
          mountFn: mountExtended,
        });

        jest.runOnlyPendingTimers();
        await waitForPromises();
      });

      it('sets showLinks to true', async () => {
        /* This spec uses .props for performance reasons. */
        expect(findLinksLayer().exists()).toBe(true);
        expect(findLinksLayer().props('showLinks')).toBe(false);
        expect(findViewSelector().props('type')).toBe(LAYER_VIEW);
        await findDependenciesToggle().vm.$emit('change', true);

        jest.runOnlyPendingTimers();
        await waitForPromises();
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
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      it('shows the hover tip in the view selector', async () => {
        await findViewSelectorToggle().vm.$emit('change', true);
        expect(findViewSelectorTrip().exists()).toBe(true);
      });
    });

    describe('when hover tip would otherwise show, but it has been previously dismissed', () => {
      beforeEach(async () => {
        createComponentWithApollo({
          data: {
            currentViewType: LAYER_VIEW,
            showLinks: true,
          },
          mountFn: mountExtended,
          calloutsList: ['pipeline_needs_hover_tip'.toUpperCase()],
        });

        jest.runOnlyPendingTimers();
        await waitForPromises();
      });

      it('does not show the hover tip', async () => {
        await findViewSelectorToggle().vm.$emit('change', true);
        expect(findViewSelectorTrip().exists()).toBe(false);
      });
    });

    describe('when feature flag is on and local storage is set', () => {
      beforeEach(async () => {
        localStorage.setItem(VIEW_TYPE_KEY, LAYER_VIEW);

        createComponentWithApollo({
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      afterEach(() => {
        localStorage.clear();
      });

      it('sets the asString prop on the LocalStorageSync component', () => {
        expect(getLocalStorageSync().props('asString')).toBe(true);
      });

      it('reads the view type from localStorage when available', () => {
        const viewSelectorNeedsSegment = wrapper
          .findComponent(GlButtonGroup)
          .findAllComponents(GlButton)
          .at(1);
        expect(viewSelectorNeedsSegment.classes()).toContain('selected');
      });
    });

    describe('when feature flag is on and local storage is set, but the graph does not use needs', () => {
      beforeEach(async () => {
        const nonNeedsResponse = { ...mockPipelineResponse };
        nonNeedsResponse.data.project.pipeline.usesNeeds = false;

        localStorage.setItem(VIEW_TYPE_KEY, LAYER_VIEW);

        pipelineDetailsHandler.mockResolvedValue(nonNeedsResponse);
        createComponentWithApollo({
          mountFn: mountExtended,
        });

        await waitForPromises();
      });

      afterEach(() => {
        localStorage.clear();
      });

      it('still passes stage type to graph', () => {
        expect(findGraph().props('viewType')).toBe(STAGE_VIEW);
      });
    });

    describe('when feature flag is on but pipeline does not use needs', () => {
      beforeEach(async () => {
        const nonNeedsResponse = { ...mockPipelineResponse };
        nonNeedsResponse.data.project.pipeline.usesNeeds = false;

        pipelineDetailsHandler.mockResolvedValue(nonNeedsResponse);
        createComponentWithApollo({
          mountFn: mountExtended,
        });

        jest.runOnlyPendingTimers();
        await waitForPromises();
      });

      it('does not appear when pipeline does not use needs', () => {
        expect(findViewSelector().exists()).toBe(false);
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
        await waitForPromises();
      });

      it('is not called', () => {
        expect(markAndMeasure).not.toHaveBeenCalled();
        expect(reportToSentry).not.toHaveBeenCalled();
        expect(reportPerformance).not.toHaveBeenCalled();
      });
    });

    describe('with metrics path', () => {
      const duration = 500;
      const numLinks = 3;
      const totalGroups = 7;
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
          stubPerformanceWebAPI();

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

          await waitForPromises();
        });

        it('attempts to collect metrics', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).not.toHaveBeenCalled();
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });

      describe('with duration and no error', () => {
        beforeEach(async () => {
          mock = new MockAdapter(axios);
          mock.onPost(metricsPath).reply(HTTP_STATUS_OK, {});

          jest.spyOn(window.performance, 'getEntriesByName').mockImplementation(() => {
            return [{ duration }];
          });

          createComponentWithApollo({
            provide: {
              metricsPath,
            },
            data: {
              currentViewType: LAYER_VIEW,
            },
          });
          await waitForPromises();
        });

        afterEach(() => {
          mock.restore();
        });

        it('calls reportPerformance with expected arguments', () => {
          expect(markAndMeasure).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalled();
          expect(reportPerformance).toHaveBeenCalledWith(metricsPath, metricsData);
          expect(reportToSentry).not.toHaveBeenCalled();
        });
      });
    });
  });
});

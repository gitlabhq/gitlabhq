import { GlSkeletonLoader } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import FlowMetricsQuery from '~/analytics/shared/graphql/flow_metrics.query.graphql';
import FOSSFlowMetricsQuery from '~/analytics/shared/graphql/foss.flow_metrics.query.graphql';
import DoraMetricsQuery from '~/analytics/shared/graphql/dora_metrics.query.graphql';
import { FLOW_METRICS, DORA_METRICS, VSA_METRICS_GROUPS } from '~/analytics/shared/constants';
import MetricTile from '~/analytics/shared/components/metric_tile.vue';
import ValueStreamsDashboardLink from '~/analytics/shared/components/value_streams_dashboard_link.vue';
import { createAlert } from '~/alert';
import { createdAfter as mockStartDate, createdBefore as mockEndDate, group } from '../mock_data';
import {
  mockGraphqlFlowMetricsResponse,
  mockGraphqlDoraMetricsResponse,
  mockGraphqlProjectFlowMetricsResponse,
} from '../../shared/helpers';
import {
  mockDoraMetricsResponseData,
  mockFlowMetricsResponseData,
  mockFOSSFlowMetricsResponseData,
  mockFlowMetricsCommitsResponseData,
  mockMetricTilesData,
} from '../../shared/mock_data';

const mockTypePolicy = {
  Query: { fields: { project: { merge: false }, group: { merge: false } } },
};

jest.mock('~/alert');

Vue.use(VueApollo);

describe('ValueStreamMetrics', () => {
  let wrapper;
  let mockApolloProvider;
  let mockFilterFn;
  let flowMetricsRequestHandler = null;
  let fossFlowMetricsRequestHandler = null;
  let doraMetricsRequestHandler = null;

  let mockFlowMetricsCommitsRequest = null;
  const mockResolvers = {
    Query: {
      flowMetricsCommits() {
        return mockFlowMetricsCommitsRequest();
      },
    },
  };

  const setGraphqlQueryHandlerResponses = ({
    doraMetricsResponse = mockDoraMetricsResponseData,
    flowMetricsResponse = mockFlowMetricsResponseData,
  } = {}) => {
    flowMetricsRequestHandler = mockGraphqlFlowMetricsResponse(flowMetricsResponse);
    doraMetricsRequestHandler = mockGraphqlDoraMetricsResponse(doraMetricsResponse);
  };

  const setFOSSGraphqlQueryHandlerResponses = ({
    fossFlowMetricsResponse = mockFOSSFlowMetricsResponseData,
  } = {}) => {
    fossFlowMetricsRequestHandler = mockGraphqlProjectFlowMetricsResponse(fossFlowMetricsResponse);
    flowMetricsRequestHandler = mockGraphqlFlowMetricsResponse({});
    doraMetricsRequestHandler = mockGraphqlDoraMetricsResponse({});
  };

  const createMockApolloProvider = ({
    flowMetricsRequest = flowMetricsRequestHandler,
    doraMetricsRequest = doraMetricsRequestHandler,
    fossFlowMetricsRequest = fossFlowMetricsRequestHandler,
  } = {}) => {
    return createMockApollo(
      [
        [FlowMetricsQuery, flowMetricsRequest],
        [FOSSFlowMetricsQuery, fossFlowMetricsRequest],
        [DoraMetricsQuery, doraMetricsRequest],
      ],
      mockResolvers,
      {
        typePolicies: mockTypePolicy,
      },
    );
  };

  const { path: requestPath } = group;

  const createComponent = async ({ props = {}, apolloProvider = null } = {}) => {
    const { requestParams, ...propsRest } = props;

    wrapper = shallowMountExtended(ValueStreamMetrics, {
      apolloProvider,
      propsData: {
        requestPath,
        requestParams: {
          startDate: mockStartDate,
          endDate: mockEndDate,
          ...requestParams,
        },
        isLicensed: true,
        ...propsRest,
      },
    });

    await waitForPromises();
  };

  const findVSDLink = () => wrapper.findComponent(ValueStreamsDashboardLink);
  const findMetrics = () => wrapper.findAllComponents(MetricTile);
  const findMetricsGroups = () => wrapper.findAllByTestId('vsa-metrics-group');
  const findCommitsMetricTile = () =>
    findMetrics().wrappers.find(
      (metricTile) => metricTile.props('metric').identifier === FLOW_METRICS.COMMITS,
    );

  const expectDoraMetricsRequests = ({
    fullPath = requestPath,
    startDate = '2018-12-15',
    endDate = '2019-01-14',
  } = {}) =>
    expect(doraMetricsRequestHandler).toHaveBeenCalledWith({
      fullPath,
      startDate,
      endDate,
      interval: 'ALL',
    });

  const expectFlowMetricsRequests = ({
    fullPath = requestPath,
    startDate = '2018-12-15',
    endDate = '2019-01-14',
    labelNames,
    projectIds,
    assigneeUsernames,
    authorUsername,
    milestoneTitle,
  } = {}) =>
    expect(flowMetricsRequestHandler).toHaveBeenCalledWith({
      fullPath,
      startDate,
      endDate,
      labelNames,
      projectIds,
      assigneeUsernames,
      authorUsername,
      milestoneTitle,
    });

  afterEach(() => {
    mockApolloProvider = null;
  });

  describe('loading requests', () => {
    beforeEach(() => {
      setGraphqlQueryHandlerResponses();

      createComponent({ apolloProvider: createMockApolloProvider() });
    });

    it('will display a loader with pending requests', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });
  });

  describe('with data loaded', () => {
    describe('default', () => {
      beforeEach(async () => {
        setGraphqlQueryHandlerResponses();
        mockApolloProvider = createMockApolloProvider();

        await createComponent({ apolloProvider: mockApolloProvider });
      });

      it('fetches dora metrics data', () => {
        expectDoraMetricsRequests();
      });

      it('fetches flow metrics data', () => {
        expectFlowMetricsRequests();
      });

      it('will not display a loading icon', () => {
        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
      });

      it('does not render the flow metrics commits tile', () => {
        expect(findCommitsMetricTile()).toBeUndefined();
      });

      describe.each`
        index | identifier                              | value       | label
        ${0}  | ${FLOW_METRICS.ISSUES}                  | ${10}       | ${'New issues'}
        ${1}  | ${FLOW_METRICS.CYCLE_TIME}              | ${'-'}      | ${'Cycle time'}
        ${2}  | ${FLOW_METRICS.LEAD_TIME}               | ${10}       | ${'Lead time'}
        ${3}  | ${FLOW_METRICS.DEPLOYS}                 | ${751}      | ${'Deploys'}
        ${4}  | ${DORA_METRICS.DEPLOYMENT_FREQUENCY}    | ${23.75}    | ${'Deployment frequency'}
        ${5}  | ${DORA_METRICS.CHANGE_FAILURE_RATE}     | ${'5.7'}    | ${'Change failure rate'}
        ${6}  | ${DORA_METRICS.LEAD_TIME_FOR_CHANGES}   | ${'0.2721'} | ${'Lead time for changes'}
        ${7}  | ${DORA_METRICS.TIME_TO_RESTORE_SERVICE} | ${'0.8343'} | ${'Time to restore service'}
      `('metric tiles', ({ identifier, index, value, label }) => {
        it(`renders a metric tile component for "${label}"`, () => {
          const metric = findMetrics().at(index);
          expect(metric.props('metric')).toMatchObject({ identifier, value, label });
          expect(metric.isVisible()).toBe(true);
        });
      });
    });

    describe('with filterFn', () => {
      beforeEach(() => {
        setGraphqlQueryHandlerResponses();

        mockApolloProvider = createMockApolloProvider();
      });

      it('with a filter function, will call the function with the metrics data', async () => {
        const filteredData = mockMetricTilesData[0];

        mockFilterFn = jest.fn(() => [filteredData]);

        await createComponent({
          apolloProvider: mockApolloProvider,
          props: {
            filterFn: mockFilterFn,
          },
        });

        expect(mockFilterFn).toHaveBeenCalled();
        expect(findMetrics().at(0).props('metric').identifier).toEqual(filteredData.identifier);
      });

      it('without a filter function, it will only update the metrics', async () => {
        await createComponent({ apolloProvider: mockApolloProvider });

        expect(mockFilterFn).not.toHaveBeenCalled();
      });
    });

    describe('with additional params', () => {
      const assigneeUsernames = ['Rei Ayanami', 'Asuka Shikinami', 'Mari Makinami'];
      const authorUsername = 'Yui Ikari';
      const milestoneTitle = 'N3i';

      beforeEach(async () => {
        setGraphqlQueryHandlerResponses();

        await createComponent({
          apolloProvider: createMockApolloProvider(),
          props: {
            requestParams: {
              startDate: new Date('2020-01-01'),
              endDate: new Date('2020-02-01'),
              projectIds: [1],
              labelNames: ['some', 'fake', 'label'],
              assigneeUsernames,
              authorUsername,
              milestoneTitle,
            },
          },
        });
      });

      it('fetches the flowMetrics data', () => {
        expectFlowMetricsRequests({
          labelNames: ['some', 'fake', 'label'],
          projectIds: [1],
          startDate: '2020-01-01',
          endDate: '2020-02-01',
          assigneeUsernames,
          authorUsername,
          milestoneTitle,
        });
      });

      it('fetches the doraMetrics data', () => {
        expectDoraMetricsRequests({
          projectIds: [1],
          startDate: '2020-01-01',
          endDate: '2020-02-01',
        });
      });
    });

    describe('with groupBy', () => {
      beforeEach(async () => {
        setGraphqlQueryHandlerResponses();

        await createComponent({
          apolloProvider: createMockApolloProvider(),
          props: { groupBy: VSA_METRICS_GROUPS },
        });
      });

      it('renders the metrics as separate groups', () => {
        const groups = findMetricsGroups();
        expect(groups).toHaveLength(VSA_METRICS_GROUPS.length);
      });

      it('renders titles for each group', () => {
        const groups = findMetricsGroups();
        groups.wrappers.forEach((g, index) => {
          const { title } = VSA_METRICS_GROUPS[index];
          expect(g.html()).toContain(title);
        });
      });
    });
  });

  describe('Value Streams Dashboard Link', () => {
    it('will render when a dashboardsPath is set', async () => {
      setGraphqlQueryHandlerResponses();

      await createComponent({
        apolloProvider: createMockApolloProvider(),
        props: {
          groupBy: VSA_METRICS_GROUPS,
          dashboardsPath: 'fake-group-path',
        },
      });

      const vsdLink = findVSDLink();

      expect(vsdLink.exists()).toBe(true);
      expect(vsdLink.props()).toEqual({ requestPath: 'fake-group-path' });
    });

    it('does not render without a dashboardsPath', async () => {
      await createComponent({
        apolloProvider: createMockApolloProvider(),
        props: { groupBy: VSA_METRICS_GROUPS },
      });

      expect(findVSDLink().exists()).toBe(false);
    });
  });

  describe('with a request failing', () => {
    describe('failing DORA metrics request', () => {
      beforeEach(async () => {
        doraMetricsRequestHandler = jest.fn().mockRejectedValue({});

        await createComponent({
          apolloProvider: createMockApolloProvider(),
        });
      });

      it('should render an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was an error while fetching DORA metrics data.',
        });
      });
    });

    describe('failing flow metrics request', () => {
      beforeEach(async () => {
        flowMetricsRequestHandler = jest.fn().mockRejectedValue({});

        await createComponent({
          apolloProvider: createMockApolloProvider(),
        });
      });

      it('should render an error message', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'There was an error while fetching flow metrics data.',
        });
      });
    });
  });

  describe('FOSS', () => {
    const defaultFossProps = { isLicensed: false, isProjectNamespace: true };

    describe('loading requests', () => {
      beforeEach(() => {
        mockFlowMetricsCommitsRequest = jest.fn();
        setFOSSGraphqlQueryHandlerResponses();

        createComponent({ apolloProvider: createMockApolloProvider(), props: defaultFossProps });
      });

      it('will display a loader with pending requests', () => {
        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
      });
    });

    describe('default', () => {
      beforeEach(async () => {
        setFOSSGraphqlQueryHandlerResponses();
        mockApolloProvider = createMockApolloProvider();

        await createComponent({ apolloProvider: mockApolloProvider, props: defaultFossProps });
      });

      it('fetches FOSS flow metrics data', () => {
        expect(fossFlowMetricsRequestHandler).toHaveBeenCalledWith({
          fullPath: requestPath,
          startDate: '2018-12-15',
          endDate: '2019-01-14',
        });
      });

      it('does not fetch dora metrics data', () => {
        expect(doraMetricsRequestHandler).not.toHaveBeenCalled();
      });

      it('does not fetch flow metrics data', () => {
        expect(flowMetricsRequestHandler).not.toHaveBeenCalled();
      });

      it('will not display a loading icon', () => {
        expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
      });

      it('does not render the flow metrics commits tile', () => {
        expect(findCommitsMetricTile()).toBeUndefined();
      });

      describe.each`
        index | identifier              | value  | label
        ${0}  | ${FLOW_METRICS.ISSUES}  | ${10}  | ${'New issues'}
        ${1}  | ${FLOW_METRICS.DEPLOYS} | ${751} | ${'Deploys'}
      `('metric tiles', ({ identifier, index, value, label }) => {
        it(`renders a metric tile component for "${label}"`, () => {
          const metric = findMetrics().at(index);
          expect(metric.props('metric')).toMatchObject({ identifier, value, label });
          expect(metric.isVisible()).toBe(true);
        });
      });
    });
  });

  describe('Project namespace', () => {
    beforeEach(async () => {
      mockFlowMetricsCommitsRequest = jest
        .fn()
        .mockResolvedValue(mockFlowMetricsCommitsResponseData);

      setGraphqlQueryHandlerResponses();
      mockApolloProvider = createMockApolloProvider();

      await createComponent({
        apolloProvider: mockApolloProvider,
        props: { isProjectNamespace: true },
      });
    });

    it('fetches dora metrics data', () => {
      expectDoraMetricsRequests();
    });

    it('fetches flow metrics data', () => {
      expectFlowMetricsRequests();
    });

    it('fetches flow metrics commits data', () => {
      expect(mockFlowMetricsCommitsRequest).toHaveBeenCalled();
    });

    it('renders the flow metrics commits tile', () => {
      const metric = findCommitsMetricTile();

      expect(metric.exists()).toBe(true);
      expect(metric.props('metric')).toMatchObject({
        identifier: 'commits',
        value: '10',
        label: 'Commits',
      });
    });
  });
});

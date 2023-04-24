import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ValueStreamMetrics from '~/analytics/shared/components/value_stream_metrics.vue';
import BaseComponent from '~/analytics/cycle_analytics/components/base.vue';
import PathNavigation from '~/analytics/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/analytics/cycle_analytics/components/stage_table.vue';
import ValueStreamFilters from '~/analytics/cycle_analytics/components/value_stream_filters.vue';
import { NOT_ENOUGH_DATA_ERROR } from '~/analytics/cycle_analytics/constants';
import initState from '~/analytics/cycle_analytics/store/state';
import {
  transformedProjectStagePathData,
  selectedStage,
  issueEvents,
  createdBefore,
  createdAfter,
  currentGroup,
  stageCounts,
  initialPaginationState as pagination,
} from '../mock_data';

const selectedStageEvents = issueEvents.events;
const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const selectedStageCount = stageCounts[selectedStage.id];
const fullPath = 'full/path/to/foo';

Vue.use(Vuex);

let wrapper;

const { path } = currentGroup;
const groupPath = `groups/${path}`;
const defaultState = {
  currentGroup,
  createdBefore,
  createdAfter,
  stageCounts,
  groupPath,
  namespace: { fullPath },
};

function createStore({ initialState = {}, initialGetters = {} }) {
  return new Vuex.Store({
    state: {
      ...initState(),
      ...defaultState,
      ...initialState,
    },
    getters: {
      pathNavigationData: () => transformedProjectStagePathData,
      filterParams: () => ({
        created_after: createdAfter,
        created_before: createdBefore,
      }),
      ...initialGetters,
    },
  });
}

function createComponent({ initialState, initialGetters } = {}) {
  return extendedWrapper(
    shallowMount(BaseComponent, {
      store: createStore({ initialState, initialGetters }),
      propsData: {
        noDataSvgPath,
        noAccessSvgPath,
      },
      stubs: {
        StageTable,
      },
    }),
  );
}

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findPathNavigation = () => wrapper.findComponent(PathNavigation);
const findFilters = () => wrapper.findComponent(ValueStreamFilters);
const findOverviewMetrics = () => wrapper.findComponent(ValueStreamMetrics);
const findStageTable = () => wrapper.findComponent(StageTable);
const findStageEvents = () => findStageTable().props('stageEvents');
const findEmptyStageTitle = () => wrapper.findComponent(GlEmptyState).props('title');
const findPagination = () => wrapper.findByTestId('vsa-stage-pagination');

const hasMetricsRequests = (reqs) => {
  const foundReqs = findOverviewMetrics().props('requests');
  expect(foundReqs.length).toEqual(reqs.length);
  expect(foundReqs.map(({ name }) => name)).toEqual(reqs);
};

describe('Value stream analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent({ initialState: { selectedStage, selectedStageEvents, pagination } });
  });

  it('renders the path navigation component', () => {
    expect(findPathNavigation().exists()).toBe(true);
  });

  it('receives the stages formatted for the path navigation', () => {
    expect(findPathNavigation().props('stages')).toBe(transformedProjectStagePathData);
  });

  it('renders the overview metrics', () => {
    expect(findOverviewMetrics().exists()).toBe(true);
  });

  it('passes requests prop to the metrics component', () => {
    hasMetricsRequests(['recent activity']);
  });

  it('renders the stage table', () => {
    expect(findStageTable().exists()).toBe(true);
  });

  it('passes the selected stage count to the stage table', () => {
    expect(findStageTable().props('stageCount')).toBe(selectedStageCount);
  });

  it('renders the stage table events', () => {
    expect(findStageEvents()).toEqual(selectedStageEvents);
  });

  it('renders the filters', () => {
    expect(findFilters().exists()).toBe(true);
  });

  it('displays the date range selector and hides the project selector', () => {
    expect(findFilters().props()).toMatchObject({
      hasProjectFilter: false,
      hasDateRangeFilter: true,
    });
  });

  it('passes the paths to the filter bar', () => {
    expect(findFilters().props()).toEqual({
      groupPath,
      namespacePath: groupPath,
      endDate: createdBefore,
      hasDateRangeFilter: true,
      hasProjectFilter: false,
      selectedProjects: [],
      startDate: createdAfter,
    });
  });

  it('does not render the loading icon', () => {
    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('renders pagination', () => {
    expect(findPagination().exists()).toBe(true);
  });

  it('does not render a link to the value streams dashboard', () => {
    expect(findOverviewMetrics().props('dashboardsPath')).toBeNull();
  });

  describe('with `cycleAnalyticsForGroups=true` license', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { features: { cycleAnalyticsForGroups: true } } });
    });

    it('passes requests prop to the metrics component', () => {
      hasMetricsRequests(['time summary', 'recent activity']);
    });
  });

  describe('with `groupAnalyticsDashboardsPage=true` and `groupLevelAnalyticsDashboard=true` license', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: {
          features: { groupAnalyticsDashboardsPage: true, groupLevelAnalyticsDashboard: true },
        },
      });
    });

    it('renders a link to the value streams dashboard', () => {
      expect(findOverviewMetrics().props('dashboardsPath')).toBeDefined();
      expect(findOverviewMetrics().props('dashboardsPath')).toBe(
        '/groups/foo/-/analytics/dashboards/value_streams_dashboard?query=full/path/to/foo',
      );
    });
  });

  describe('isLoading = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { isLoading: true },
      });
    });

    it('renders the path navigation component with prop `loading` set to true', () => {
      expect(findPathNavigation().props('loading')).toBe(true);
    });

    it('does not render the stage table', () => {
      expect(findStageTable().exists()).toBe(false);
    });

    it('renders the overview metrics', () => {
      expect(findOverviewMetrics().exists()).toBe(true);
    });

    it('renders the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('isLoadingStage = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { isLoadingStage: true },
      });
    });

    it('renders the stage table with a loading icon', () => {
      const tableWrapper = findStageTable();
      expect(tableWrapper.exists()).toBe(true);
      expect(tableWrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });

    it('renders the path navigation loading state', () => {
      expect(findPathNavigation().props('loading')).toBe(true);
    });
  });

  describe('isEmptyStage = true', () => {
    const emptyStageParams = {
      isEmptyStage: true,
      selectedStage: { ...selectedStage, emptyStageText: 'This stage is empty' },
    };
    beforeEach(() => {
      wrapper = createComponent({ initialState: emptyStageParams });
    });

    it('renders the empty stage with `Not enough data` message', () => {
      expect(findEmptyStageTitle()).toBe(NOT_ENOUGH_DATA_ERROR);
    });

    describe('with a selectedStageError', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            ...emptyStageParams,
            selectedStageError: 'There is too much data to calculate',
          },
        });
      });

      it('renders the empty stage with `There is too much data to calculate` message', () => {
        expect(findEmptyStageTitle()).toBe('There is too much data to calculate');
      });
    });
  });

  describe('without a selected stage', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialGetters: { pathNavigationData: () => [] },
        initialState: { selectedStage: null, isEmptyStage: true },
      });
    });

    it('renders the stage table', () => {
      expect(findStageTable().exists()).toBe(true);
    });

    it('does not render the path navigation', () => {
      expect(findPathNavigation().exists()).toBe(false);
    });

    it('does not render the stage table events', () => {
      expect(findStageEvents()).toHaveLength(0);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});

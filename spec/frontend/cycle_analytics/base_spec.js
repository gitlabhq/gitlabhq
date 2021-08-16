import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BaseComponent from '~/cycle_analytics/components/base.vue';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import StageTable from '~/cycle_analytics/components/stage_table.vue';
import ValueStreamMetrics from '~/cycle_analytics/components/value_stream_metrics.vue';
import { NOT_ENOUGH_DATA_ERROR } from '~/cycle_analytics/constants';
import initState from '~/cycle_analytics/store/state';
import {
  permissions,
  transformedProjectStagePathData,
  selectedStage,
  issueEvents,
  createdBefore,
  createdAfter,
  currentGroup,
  stageCounts,
} from './mock_data';

const selectedStageEvents = issueEvents.events;
const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';
const selectedStageCount = stageCounts[selectedStage.id];
const fullPath = 'full/path/to/foo';

Vue.use(Vuex);

let wrapper;

const defaultState = {
  permissions,
  currentGroup,
  createdBefore,
  createdAfter,
  stageCounts,
  endpoints: { fullPath },
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
const findOverviewMetrics = () => wrapper.findComponent(ValueStreamMetrics);
const findStageTable = () => wrapper.findComponent(StageTable);
const findStageEvents = () => findStageTable().props('stageEvents');
const findEmptyStageTitle = () => wrapper.findComponent(GlEmptyState).props('title');

const hasMetricsRequests = (reqs) => {
  const foundReqs = findOverviewMetrics().props('requests');
  expect(foundReqs.length).toEqual(reqs.length);
  expect(foundReqs.map(({ name }) => name)).toEqual(reqs);
};

describe('Value stream analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent({ initialState: { selectedStage, selectedStageEvents } });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
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

  it('does not render the loading icon', () => {
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('with `cycleAnalyticsForGroups=true` license', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { features: { cycleAnalyticsForGroups: true } } });
    });

    it('passes requests prop to the metrics component', () => {
      hasMetricsRequests(['time summary', 'recent activity']);
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
      expect(tableWrapper.find(GlLoadingIcon).exists()).toBe(true);
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

  describe('without enough permissions', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: {
          selectedStage,
          permissions: {
            ...permissions,
            [selectedStage.id]: false,
          },
        },
      });
    });

    it('renders the empty stage with `You need permission.` message', () => {
      expect(findEmptyStageTitle()).toBe('You need permission.');
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

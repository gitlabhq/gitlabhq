import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BaseComponent from '~/cycle_analytics/components/base.vue';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import initState from '~/cycle_analytics/store/state';
import { selectedStage, convertedEvents as selectedStageEvents } from './mock_data';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';

Vue.use(Vuex);

let wrapper;

function createStore({ initialState = {} }) {
  return new Vuex.Store({
    state: {
      ...initState(),
      ...initialState,
    },
    getters: {
      pathNavigationData: () => [],
    },
  });
}

function createComponent({ initialState } = {}) {
  return extendedWrapper(
    shallowMount(BaseComponent, {
      store: createStore({ initialState }),
      propsData: {
        noDataSvgPath,
        noAccessSvgPath,
      },
    }),
  );
}

const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findPathNavigation = () => wrapper.findComponent(PathNavigation);
const findOverviewMetrics = () => wrapper.findByTestId('vsa-stage-overview-metrics');
const findStageTable = () => wrapper.findByTestId('vsa-stage-table');
const findEmptyStage = () => wrapper.findComponent(GlEmptyState);
const findStageEvents = () => wrapper.findByTestId('stage-table-events');

describe('Value stream analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent({
      initialState: {
        isLoading: false,
        isLoadingStage: false,
        isEmptyStage: false,
        selectedStageEvents,
        selectedStage,
        selectedStageError: '',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the path navigation component', () => {
    expect(findPathNavigation().exists()).toBe(true);
  });

  it('renders the overview metrics', () => {
    expect(findOverviewMetrics().exists()).toBe(true);
  });

  it('renders the stage table', () => {
    expect(findStageTable().exists()).toBe(true);
  });

  it('renders the stage table events', () => {
    expect(findEmptyStage().exists()).toBe(false);
    expect(findStageEvents().exists()).toBe(true);
  });

  it('does not render the loading icon', () => {
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('isLoading = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { isLoading: true },
      });
    });

    it('renders the path navigation component with prop `loading` set to true', () => {
      expect(findPathNavigation().html()).toMatchSnapshot();
    });

    it('does not render the overview metrics', () => {
      expect(findOverviewMetrics().exists()).toBe(false);
    });

    it('does not render the stage table', () => {
      expect(findStageTable().exists()).toBe(false);
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
  });

  describe('isEmptyStage = true', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { selectedStage, isEmptyStage: true },
      });
    });

    it('renders the empty stage with `Not enough data` message', () => {
      expect(findEmptyStage().html()).toMatchSnapshot();
    });

    describe('with a selectedStageError', () => {
      beforeEach(() => {
        wrapper = createComponent({
          initialState: {
            selectedStage,
            isEmptyStage: true,
            selectedStageError: 'There is too much data to calculate',
          },
        });
      });

      it('renders the empty stage with `There is too much data to calculate` message', () => {
        expect(findEmptyStage().html()).toMatchSnapshot();
      });
    });
  });

  describe('without enough permissions', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { selectedStage: { ...selectedStage, isUserAllowed: false } },
      });
    });

    it('renders the empty stage with `You need permission` message', () => {
      expect(findEmptyStage().html()).toMatchSnapshot();
    });
  });

  describe('without a selected stage', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialState: { selectedStage: null, isEmptyStage: true },
      });
    });

    it('renders the stage table', () => {
      expect(findStageTable().exists()).toBe(true);
    });

    it('does not render the path navigation component', () => {
      expect(findPathNavigation().exists()).toBe(false);
    });

    it('does not render the stage table events', () => {
      expect(findStageEvents().exists()).toBe(false);
    });

    it('does not render the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });
});

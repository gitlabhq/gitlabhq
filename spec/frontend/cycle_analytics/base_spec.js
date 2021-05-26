import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import Component from '~/cycle_analytics/components/base.vue';
import PathNavigation from '~/cycle_analytics/components/path_navigation.vue';
import createStore from '~/cycle_analytics/store';

const noDataSvgPath = 'path/to/no/data';
const noAccessSvgPath = 'path/to/no/access';

const localVue = createLocalVue();
localVue.use(Vuex);

let wrapper;

function createComponent() {
  const store = createStore();
  return extendedWrapper(
    shallowMount(Component, {
      localVue,
      store,
      propsData: {
        noDataSvgPath,
        noAccessSvgPath,
      },
    }),
  );
}

const findPathNavigation = () => wrapper.findComponent(PathNavigation);
const findOverviewMetrics = () => wrapper.findByTestId('vsa-stage-overview-metrics');
const findStageTable = () => wrapper.findByTestId('vsa-stage-table');

describe('Value stream analytics component', () => {
  beforeEach(() => {
    wrapper = createComponent();
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
});

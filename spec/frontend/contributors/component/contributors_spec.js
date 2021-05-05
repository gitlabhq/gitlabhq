import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import ContributorsCharts from '~/contributors/components/contributors.vue';
import { createStore } from '~/contributors/stores';
import axios from '~/lib/utils/axios_utils';

let wrapper;
let mock;
let store;
const Component = Vue.extend(ContributorsCharts);
const endpoint = 'contributors';
const branch = 'main';
const chartData = [
  { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-05-05' },
  { author_name: 'John', author_email: 'jawnnypoo@gmail.com', date: '2019-03-03' },
];

function factory() {
  mock = new MockAdapter(axios);
  jest.spyOn(axios, 'get');
  mock.onGet().reply(200, chartData);
  store = createStore();

  wrapper = mount(Component, {
    propsData: {
      endpoint,
      branch,
    },
    stubs: {
      GlLoadingIcon: true,
      GlAreaChart: true,
    },
    store,
  });
}

describe('Contributors charts', () => {
  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  it('should fetch chart data when mounted', () => {
    expect(axios.get).toHaveBeenCalledWith(endpoint);
  });

  it('should display loader whiled loading data', () => {
    wrapper.vm.$store.state.loading = true;
    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('.contributors-loader').exists()).toBe(true);
    });
  });

  it('should render charts when loading completed and there is chart data', () => {
    wrapper.vm.$store.state.loading = false;
    wrapper.vm.$store.state.chartData = chartData;
    return wrapper.vm.$nextTick(() => {
      expect(wrapper.find('.contributors-loader').exists()).toBe(false);
      expect(wrapper.find('.contributors-charts').exists()).toBe(true);
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});

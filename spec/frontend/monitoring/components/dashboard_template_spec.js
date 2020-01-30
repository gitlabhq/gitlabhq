import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { propsData } from '../init_utils';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockImplementation(param => {
    if (param === 'start') return ['2020-01-01T18:27:47.000Z'];
    if (param === 'end') return ['2020-01-01T18:57:47.000Z'];
    return [];
  }),
}));

describe('Dashboard template', () => {
  let wrapper;
  let store;
  let mock;

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    mock.restore();
  });

  it('matches the default snapshot', () => {
    wrapper = shallowMount(Dashboard, {
      propsData: { ...propsData },
      methods: {
        fetchData: jest.fn(),
      },
      store,
    });

    expect(wrapper.element).toMatchSnapshot();
  });
});

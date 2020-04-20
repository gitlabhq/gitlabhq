import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { propsData } from '../mock_data';

jest.mock('~/lib/utils/url_utility');

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

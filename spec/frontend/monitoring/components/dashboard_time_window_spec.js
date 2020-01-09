import { mount } from '@vue/test-utils';
import { GlDropdownItem } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import statusCodes from '~/lib/utils/http_status';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { propsData, setupComponentStore } from '../init_utils';
import { metricsGroupsAPIResponse, mockApiEndpoint } from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockImplementation(param => {
    if (param === 'start') return ['2019-10-01T18:27:47.000Z'];
    if (param === 'end') return ['2019-10-01T18:57:47.000Z'];
    return [];
  }),
  mergeUrlParams: jest.fn().mockReturnValue('#'),
}));

describe('dashboard time window', () => {
  let store;
  let wrapper;
  let mock;

  const createComponentWrapperMounted = (props = {}, options = {}) => {
    wrapper = mount(Dashboard, {
      sync: false,
      propsData: { ...propsData, ...props },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
    mock.restore();
  });

  it('shows an error message if invalid url parameters are passed', done => {
    mock.onGet(mockApiEndpoint).reply(statusCodes.OK, metricsGroupsAPIResponse);

    createComponentWrapperMounted(
      { hasMetrics: true },
      { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
    );

    setupComponentStore(wrapper);

    wrapper.vm
      .$nextTick()
      .then(() => {
        const timeWindowDropdownItems = wrapper
          .find('.js-time-window-dropdown')
          .findAll(GlDropdownItem);
        const activeItem = timeWindowDropdownItems.wrappers.filter(itemWrapper =>
          itemWrapper.find('.active').exists(),
        );

        expect(activeItem.length).toBe(1);

        done();
      })
      .catch(done.fail);
  });
});

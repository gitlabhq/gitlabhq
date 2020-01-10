import { mount } from '@vue/test-utils';
import createFlash from '~/flash';
import MockAdapter from 'axios-mock-adapter';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { propsData } from '../init_utils';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/flash');

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockReturnValue('<script>alert("XSS")</script>'),
}));

describe('dashboard invalid url parameters', () => {
  let store;
  let wrapper;
  let mock;

  const createMountedWrapper = (props = {}, options = {}) => {
    wrapper = mount(Dashboard, {
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
    createMountedWrapper(
      { hasMetrics: true },
      { attachToDocument: true, stubs: ['graph-group', 'panel-type'] },
    );

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(createFlash).toHaveBeenCalled();
        done();
      })
      .catch(done.fail);
  });
});

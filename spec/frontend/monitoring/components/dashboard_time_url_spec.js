import { mount, createLocalVue } from '@vue/test-utils';
import createFlash from '~/flash';
import Dashboard from '~/monitoring/components/dashboard.vue';
import { createStore } from '~/monitoring/stores';
import { propsData } from '../init_utils';

const localVue = createLocalVue();

jest.mock('~/flash');

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockReturnValue('<script>alert("XSS")</script>'),
}));

describe('dashboard invalid url parameters', () => {
  let store;
  let wrapper;

  const createMountedWrapper = (props = {}, options = {}) => {
    wrapper = mount(localVue.extend(Dashboard), {
      localVue,
      sync: false,
      propsData: { ...propsData, ...props },
      store,
      ...options,
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
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

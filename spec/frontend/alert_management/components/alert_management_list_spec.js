import { createLocalVue, mount } from '@vue/test-utils';
import { GlEmptyState, GlTable, GlAlert } from '@gitlab/ui';
import Vuex from 'vuex';
import stubChildren from 'helpers/stub_children';
import AlertManagementList from '~/alert_management/components/alert_management_list.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('AlertManagementList', () => {
  let wrapper;
  let store;

  const findAlertsTable = () => wrapper.find(GlTable);
  const findAlert = () => wrapper.find(GlAlert);

  function mountComponent({ stubs = {}, alertManagementEnabled = false } = {}) {
    wrapper = mount(AlertManagementList, {
      localVue,
      store,
      propsData: {
        indexPath: '/path',
        enableAlertManagementPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
        alertManagementEnabled,
      },
      stubs: {
        ...stubChildren(AlertManagementList),
        ...stubs,
      },
    });
  }

  beforeEach(() => {
    store = new Vuex.Store({
      modules: {
        list: {
          namespaced: true,
        },
      },
    });
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      store = null;
    }
  });

  describe('alert management feature renders empty state', () => {
    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('Alerts table', () => {
    it('shows empty list', () => {
      store.state.list = {
        alerts: [],
        loading: false,
      };

      mountComponent({ alertManagementEnabled: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(findAlertsTable().exists()).toBe(true);
        expect(findAlert().text()).toContain('No alerts available to display');
      });
    });
  });
});

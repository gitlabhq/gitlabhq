import { mount } from '@vue/test-utils';
import { GlEmptyState, GlTable, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import stubChildren from 'helpers/stub_children';
import AlertManagementList from '~/alert_management/components/alert_management_list.vue';

describe('AlertManagementList', () => {
  let wrapper;

  const findAlertsTable = () => wrapper.find(GlTable);
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);

  function mountComponent({
    stubs = {},
    props = {
      alertManagementEnabled: false,
      userCanEnableAlertManagement: false,
    },
    data = {},
    loading = false,
  } = {}) {
    wrapper = mount(AlertManagementList, {
      propsData: {
        indexPath: '/path',
        enableAlertManagementPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
        ...props,
      },
      data() {
        return data;
      },
      mocks: {
        $apollo: {
          queries: {
            alerts: {
              loading,
            },
          },
        },
      },
      stubs: {
        ...stubChildren(AlertManagementList),
        ...stubs,
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('alert management feature renders empty state', () => {
    it('shows empty state', () => {
      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
    });
  });

  describe('Alerts table', () => {
    it('loading state', () => {
      mountComponent({
        stubs: { GlTable },
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: null },
        loading: true,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
    });

    it('error state', () => {
      mountComponent({
        stubs: { GlTable },
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: null, errored: true },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().props().variant).toBe('danger');
    });

    it('empty state', () => {
      mountComponent({
        stubs: { GlTable },
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: [], errored: false },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().props().variant).toBe('info');
    });
  });
});

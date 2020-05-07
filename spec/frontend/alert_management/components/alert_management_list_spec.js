import { mount } from '@vue/test-utils';
import {
  GlEmptyState,
  GlTable,
  GlAlert,
  GlLoadingIcon,
  GlNewDropdown,
  GlBadge,
  GlIcon,
  GlTab,
} from '@gitlab/ui';
import AlertManagementList from '~/alert_management/components/alert_management_list.vue';
import { ALERTS_STATUS_TABS } from '../../../../app/assets/javascripts/alert_management/constants';

import mockAlerts from '../mocks/alerts.json';

describe('AlertManagementList', () => {
  let wrapper;

  const findAlertsTable = () => wrapper.find(GlTable);
  const findAlerts = () => wrapper.findAll('table tbody tr');
  const findAlert = () => wrapper.find(GlAlert);
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findStatusDropdown = () => wrapper.find(GlNewDropdown);
  const findStatusFilterTabs = () => wrapper.findAll(GlTab);
  const findNumberOfAlertsBadge = () => wrapper.findAll(GlBadge);

  function mountComponent({
    props = {
      alertManagementEnabled: false,
      userCanEnableAlertManagement: false,
    },
    data = {},
    loading = false,
    alertListStatusFilteringEnabled = false,
    stubs = {},
  } = {}) {
    wrapper = mount(AlertManagementList, {
      propsData: {
        projectPath: 'gitlab-org/gitlab',
        enableAlertManagementPath: '/link',
        emptyAlertSvgPath: 'illustration/path',
        ...props,
      },
      provide: {
        glFeatures: { alertListStatusFilteringEnabled },
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
      stubs,
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

  describe('Status Filter Tabs', () => {
    describe('alertListStatusFilteringEnabled feature flag enabled', () => {
      beforeEach(() => {
        mountComponent({
          props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
          data: { alerts: mockAlerts },
          loading: false,
          alertListStatusFilteringEnabled: true,
          stubs: {
            GlTab: true,
          },
        });
      });

      it('should display filter tabs for all statuses', () => {
        const tabs = findStatusFilterTabs().wrappers;
        tabs.forEach((tab, i) => {
          expect(tab.text()).toContain(ALERTS_STATUS_TABS[i].title);
        });
      });

      it('should have number of items badge along with status tab', () => {
        expect(findNumberOfAlertsBadge().length).toEqual(ALERTS_STATUS_TABS.length);
        expect(
          findNumberOfAlertsBadge()
            .at(0)
            .text(),
        ).toEqual(`${mockAlerts.length}`);
      });
    });

    describe('alertListStatusFilteringEnabled feature flag disabled', () => {
      beforeEach(() => {
        mountComponent({
          props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
          data: { alerts: mockAlerts },
          loading: false,
          alertListStatusFilteringEnabled: false,
          stubs: {
            GlTab: true,
          },
        });
      });

      it('should NOT display tabs', () => {
        expect(findStatusFilterTabs()).not.toExist();
      });
    });
  });

  describe('Alerts table', () => {
    it('loading state', () => {
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: null },
        loading: true,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findLoader().exists()).toBe(true);
    });

    it('error state', () => {
      mountComponent({
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
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: [], errored: false },
        loading: false,
      });
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlertsTable().text()).toContain('No alerts to display');
      expect(findLoader().exists()).toBe(false);
      expect(findAlert().props().variant).toBe('info');
    });

    it('has data state', () => {
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: mockAlerts, errored: false },
        loading: false,
      });
      expect(findLoader().exists()).toBe(false);
      expect(findAlertsTable().exists()).toBe(true);
      expect(findAlerts()).toHaveLength(mockAlerts.length);
    });

    it('displays status dropdown', () => {
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: mockAlerts, errored: false },
        loading: false,
      });
      expect(findStatusDropdown().exists()).toBe(true);
    });

    it('shows correct severity icons', () => {
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: mockAlerts, errored: false },
        loading: false,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlTable).exists()).toBe(true);
        expect(
          findAlertsTable()
            .find(GlIcon)
            .classes('icon-critical'),
        ).toBe(true);
      });
    });
  });
});

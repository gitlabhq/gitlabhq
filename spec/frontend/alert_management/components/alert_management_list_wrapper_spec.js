import { shallowMount } from '@vue/test-utils';
import AlertManagementList from '~/alert_management/components/alert_management_list_wrapper.vue';
import { trackAlertListViewsOptions } from '~/alert_management/constants';
import mockAlerts from '../mocks/alerts.json';
import Tracking from '~/tracking';

describe('AlertManagementList', () => {
  let wrapper;

  function mountComponent({
    props = {
      alertManagementEnabled: false,
      userCanEnableAlertManagement: false,
    },
    data = {},
    stubs = {},
  } = {}) {
    wrapper = shallowMount(AlertManagementList, {
      propsData: {
        projectPath: 'gitlab-org/gitlab',
        enableAlertManagementPath: '/link',
        populatingAlertsHelpUrl: '/help/help-page.md#populating-alert-data',
        emptyAlertSvgPath: 'illustration/path',
        ...props,
      },
      data() {
        return data;
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

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mountComponent({
        props: { alertManagementEnabled: true, userCanEnableAlertManagement: true },
        data: { alerts: { list: mockAlerts } },
      });
    });

    it('should track alert list page views', () => {
      const { category, action } = trackAlertListViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });
});

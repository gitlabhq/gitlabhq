import merge from 'lodash/merge';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import DescriptionComponent from '~/issues/show/components/description.vue';
import HighlightBar from '~/issues/show/components/incidents/highlight_bar.vue';
import IncidentTabs, {
  incidentTabsI18n,
} from '~/issues/show/components/incidents/incident_tabs.vue';
import INVALID_URL from '~/lib/utils/invalid_url';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import { descriptionProps } from '../../mock_data/mock_data';

const push = jest.fn();
const $router = {
  push,
};

const mockAlert = {
  __typename: 'AlertManagementAlert',
  detailsUrl: INVALID_URL,
  iid: '1',
};

const defaultMocks = {
  $apollo: {
    queries: {
      alert: {
        loading: true,
      },
      timelineEvents: {
        loading: false,
      },
    },
  },
  $route: { params: {} },
  $router,
};

describe('Incident Tabs component', () => {
  let wrapper;

  const mountComponent = ({
    data = {},
    options = {},
    mount = shallowMountExtended,
    hasLinkedAlerts = false,
    mocks = {},
  } = {}) => {
    wrapper = mount(
      IncidentTabs,
      merge(
        {
          propsData: {
            ...descriptionProps,
          },
          stubs: {
            DescriptionComponent: true,
            IncidentMetricTab: true,
          },
          provide: {
            fullPath: '',
            iid: '',
            projectId: '',
            issuableId: '',
            uploadMetricsFeatureAvailable: true,
            slaFeatureAvailable: true,
            canUpdate: true,
            canUpdateTimelineEvent: true,
            hasLinkedAlerts,
          },
          data() {
            return { alert: mockAlert, ...data };
          },
          mocks: { ...defaultMocks, ...mocks },
        },
        options,
      ),
    );
  };

  const findSummaryTab = () => wrapper.findByTestId('summary-tab');
  const findTimelineTab = () => wrapper.findByTestId('timeline-tab');
  const findAlertDetailsTab = () => wrapper.findByTestId('alert-details-tab');
  const findAlertDetailsComponent = () => wrapper.findComponent(AlertDetailsTable);
  const findDescriptionComponent = () => wrapper.findComponent(DescriptionComponent);
  const findHighlightBarComponent = () => wrapper.findComponent(HighlightBar);
  const findTabButtonByFilter = (filter) => wrapper.findAllByRole('tab').filter(filter);
  const findTimelineTabButton = () =>
    findTabButtonByFilter((inner) => inner.text() === incidentTabsI18n.timelineTitle).at(0);
  const findActiveTabs = () => findTabButtonByFilter((inner) => inner.classes('active'));

  describe('with no alerts', () => {
    beforeEach(() => {
      mountComponent({ data: { alert: null } });
    });

    it('does not show the alert details tab option', () => {
      expect(findAlertDetailsComponent().exists()).toBe(false);
    });
  });

  describe('with an alert present', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the summary tab', () => {
      expect(findSummaryTab().exists()).toBe(true);
      expect(findSummaryTab().attributes('title')).toBe(incidentTabsI18n.summaryTitle);
    });

    it('renders the timeline tab', () => {
      expect(findTimelineTab().exists()).toBe(true);
      expect(findTimelineTab().attributes('title')).toBe(incidentTabsI18n.timelineTitle);
    });

    it('renders the alert details tab', () => {
      mountComponent({ hasLinkedAlerts: true });
      expect(findAlertDetailsTab().exists()).toBe(true);
      expect(findAlertDetailsTab().attributes('title')).toBe('Alert details');
    });

    it('renders the alert details table with the correct props', () => {
      mountComponent({ hasLinkedAlerts: true });
      const alert = { iid: mockAlert.iid };

      expect(findAlertDetailsComponent().props('alert')).toMatchObject(alert);
      expect(findAlertDetailsComponent().props('loading')).toBe(true);
    });

    it('renders the description component with highlight bar', () => {
      expect(findDescriptionComponent().exists()).toBe(true);
      expect(findHighlightBarComponent().exists()).toBe(true);
    });

    it('renders the highlight bar component with the correct props', () => {
      const alert = { detailsUrl: mockAlert.detailsUrl };

      expect(findHighlightBarComponent().props('alert')).toMatchObject(alert);
    });

    it('passes all props to the description component', () => {
      expect(findDescriptionComponent().props()).toMatchObject(descriptionProps);
    });
  });

  describe('Snowplow tracking', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      mountComponent();
    });

    it('should track incident details views', () => {
      const { category, action } = trackIncidentDetailsViewsOptions;
      expect(Tracking.event).toHaveBeenCalledWith(category, action);
    });
  });

  describe('tab changing', () => {
    beforeEach(() => {
      mountComponent({ mount: mountExtended });
    });

    it('shows only the summary tab by default', () => {
      expect(findActiveTabs()).toHaveLength(1);
      expect(findActiveTabs().at(0).text()).toBe(incidentTabsI18n.summaryTitle);
    });

    it("shows the timeline tab after it's clicked", async () => {
      await findTimelineTabButton().trigger('click');

      expect(findActiveTabs()).toHaveLength(1);
      expect(findActiveTabs().at(0).text()).toBe(incidentTabsI18n.timelineTitle);
      expect(push).toHaveBeenCalledWith('/timeline');
    });
  });

  describe('loading page with tab', () => {
    it('shows the timeline tab when timeline path is passed', async () => {
      mountComponent({
        mount: mountExtended,
        mocks: { $route: { params: { tabId: 'timeline' } } },
      });
      await nextTick();
      expect(findActiveTabs()).toHaveLength(1);
      expect(findActiveTabs().at(0).text()).toBe(incidentTabsI18n.timelineTitle);
    });

    it('shows the alerts tab when timeline path is passed', async () => {
      mountComponent({
        mount: mountExtended,
        mocks: { $route: { params: { tabId: 'alerts' } } },
        hasLinkedAlerts: true,
      });
      await nextTick();
      expect(findActiveTabs()).toHaveLength(1);
      expect(findActiveTabs().at(0).text()).toBe(incidentTabsI18n.alertsTitle);
    });

    it('shows the metrics tab when metrics path is passed', async () => {
      mountComponent({
        mount: mountExtended,
        mocks: { $route: { params: { tabId: 'metrics' } } },
      });
      await nextTick();
      expect(findActiveTabs()).toHaveLength(1);
      expect(findActiveTabs().at(0).text()).toBe(incidentTabsI18n.metricsTitle);
    });
  });
});

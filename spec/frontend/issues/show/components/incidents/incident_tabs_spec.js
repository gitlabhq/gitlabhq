import { GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import merge from 'lodash/merge';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import DescriptionComponent from '~/issues/show/components/description.vue';
import HighlightBar from '~/issues/show/components/incidents/highlight_bar.vue';
import IncidentTabs from '~/issues/show/components/incidents/incident_tabs.vue';
import INVALID_URL from '~/lib/utils/invalid_url';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import { descriptionProps } from '../../mock_data/mock_data';

const mockAlert = {
  __typename: 'AlertManagementAlert',
  detailsUrl: INVALID_URL,
  iid: '1',
};

describe('Incident Tabs component', () => {
  let wrapper;

  const mountComponent = (data = {}, options = {}) => {
    wrapper = shallowMount(
      IncidentTabs,
      merge(
        {
          propsData: {
            ...descriptionProps,
          },
          stubs: {
            DescriptionComponent: true,
            MetricsTab: true,
          },
          provide: {
            fullPath: '',
            iid: '',
            uploadMetricsFeatureAvailable: true,
            glFeatures: { incidentTimelineEventTab: true, incidentTimelineEvents: true },
          },
          data() {
            return { alert: mockAlert, ...data };
          },
          mocks: {
            $apollo: {
              queries: {
                alert: {
                  loading: true,
                },
              },
            },
          },
        },
        options,
      ),
    );
  };

  const findTabs = () => wrapper.findAll(GlTab);
  const findSummaryTab = () => findTabs().at(0);
  const findMetricsTab = () => wrapper.find('[data-testid="metrics-tab"]');
  const findTimelineTab = () => wrapper.find('[data-testid="timeline-events-tab"]');
  const findAlertDetailsTab = () => wrapper.find('[data-testid="alert-details-tab"]');
  const findAlertDetailsComponent = () => wrapper.find(AlertDetailsTable);
  const findDescriptionComponent = () => wrapper.find(DescriptionComponent);
  const findHighlightBarComponent = () => wrapper.find(HighlightBar);

  describe('empty state', () => {
    beforeEach(() => {
      mountComponent({ alert: null });
    });

    it('does not show the alert details tab', () => {
      expect(findAlertDetailsComponent().exists()).toBe(false);
    });
  });

  describe('incident timeline tab', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the timeline tab when feature flag is enabled', () => {
      expect(findTimelineTab().exists()).toBe(true);
      expect(findTimelineTab().attributes('title')).toBe('Timeline');
    });

    it('does not render timeline tab when feature flag is disabled', () => {
      mountComponent({}, { provide: { glFeatures: { incidentTimelineEventTab: false } } });

      expect(findTimelineTab().exists()).toBe(false);
    });

    it('does not render timeline tab when not available in license', () => {
      mountComponent({}, { provide: { glFeatures: { incidentTimelineEvents: false } } });

      expect(findTimelineTab().exists()).toBe(false);
    });
  });

  describe('with an alert present', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders the summary tab', () => {
      expect(findSummaryTab().exists()).toBe(true);
      expect(findSummaryTab().attributes('title')).toBe('Summary');
    });

    it('renders the alert details tab', () => {
      expect(findAlertDetailsTab().exists()).toBe(true);
      expect(findAlertDetailsTab().attributes('title')).toBe('Alert details');
    });

    it('renders the alert details table with the correct props', () => {
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

  describe('upload metrics feature available', () => {
    it('shows the metric tab when metrics are available', () => {
      mountComponent({}, { provide: { uploadMetricsFeatureAvailable: true } });

      expect(findMetricsTab().exists()).toBe(true);
    });

    it('hides the tab when metrics are not available', () => {
      mountComponent({}, { provide: { uploadMetricsFeatureAvailable: false } });

      expect(findMetricsTab().exists()).toBe(false);
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
});

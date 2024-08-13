<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import DescriptionComponent from '../description.vue';
import getAlert from './graphql/queries/get_alert.graphql';
import HighlightBar from './highlight_bar.vue';
import TimelineTab from './timeline_events_tab.vue';

export const incidentTabsI18n = Object.freeze({
  summaryTitle: s__('Incident|Summary'),
  metricsTitle: s__('Incident|Metrics'),
  alertsTitle: s__('Incident|Alert details'),
  timelineTitle: s__('Incident|Timeline'),
});

export const TAB_NAMES = Object.freeze({
  SUMMARY: '',
  ALERTS: 'alerts',
  METRICS: 'metrics',
  TIMELINE: 'timeline',
});

export default {
  components: {
    AlertDetailsTable,
    DescriptionComponent,
    GlTab,
    GlTabs,
    HighlightBar,
    TimelineTab,
    IncidentMetricTab: () =>
      import('ee_component/issues/show/components/incidents/incident_metric_tab.vue'),
  },
  inject: ['fullPath', 'iid', 'hasLinkedAlerts', 'uploadMetricsFeatureAvailable'],
  i18n: incidentTabsI18n,
  apollo: {
    alert: {
      query: getAlert,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data?.project?.issue?.alertManagementAlert;
      },
      error() {
        createAlert({
          message: s__('Incident|There was an issue loading alert data. Please try again.'),
        });
      },
    },
  },
  data() {
    return {
      alert: null,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.alert.loading;
    },
    activeTabIndex() {
      const { tabId } = this.$route.params;
      return tabId ? this.tabMapping.tabNamesToIndex[tabId] : 0;
    },
    tabMapping() {
      const availableTabs = [TAB_NAMES.SUMMARY];

      if (this.uploadMetricsFeatureAvailable) {
        availableTabs.push(TAB_NAMES.METRICS);
      }
      if (this.hasLinkedAlerts) {
        availableTabs.push(TAB_NAMES.ALERTS);
      }

      availableTabs.push(TAB_NAMES.TIMELINE);

      const tabNamesToIndex = {};
      const tabIndexToName = {};

      availableTabs.forEach((item, index) => {
        tabNamesToIndex[item] = index;
        tabIndexToName[index] = item;
      });

      return { tabNamesToIndex, tabIndexToName };
    },
    currentTabIndex: {
      get() {
        return this.activeTabIndex;
      },
      set(index) {
        const newPath = `/${this.tabMapping.tabIndexToName[index]}`;
        // Only push if the new path differs from the old path.
        if (newPath !== this.$route.path) {
          this.$router.push(newPath);
          this.updateJsIssueWidgets(index);
        }
      },
    },
  },
  mounted() {
    this.trackPageViews();
    this.updateJsIssueWidgets(this.activeTabIndex);
  },
  methods: {
    trackPageViews() {
      const { category, action } = trackIncidentDetailsViewsOptions;
      Tracking.event(category, action);
    },
    updateJsIssueWidgets(tabIndex) {
      /**
       * TODO: Implement a solution that does not violate Vue principles in using
       * DOM manipulation directly (#361618)
       */
      const parent = document.querySelector('.js-issue-details');

      if (parent !== null) {
        const itemsToHide = parent.querySelectorAll('.js-issue-widgets');
        const lineSeparator = parent.querySelector('.js-detail-page-description');
        const editButton = document.querySelector('.js-issuable-edit');
        const isSummaryTab = tabIndex === 0;

        lineSeparator.classList.toggle('gl-border-b-0', !isSummaryTab);

        itemsToHide.forEach((item) => {
          item.classList.toggle('gl-hidden', !isSummaryTab);
        });

        editButton?.classList.toggle('md:!gl-block', isSummaryTab);
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs
      v-model="currentTabIndex"
      content-class="gl-leading-reset"
      class="-gl-mt-3"
      data-testid="incident-tabs"
    >
      <gl-tab :title="$options.i18n.summaryTitle" data-testid="summary-tab">
        <highlight-bar :alert="alert" />
        <description-component v-bind="$attrs" v-on="$listeners" />
      </gl-tab>
      <gl-tab
        v-if="uploadMetricsFeatureAvailable"
        :title="$options.i18n.metricsTitle"
        data-testid="metrics-tab"
      >
        <incident-metric-tab />
      </gl-tab>
      <gl-tab
        v-if="hasLinkedAlerts"
        class="alert-management-details"
        :title="$options.i18n.alertsTitle"
        data-testid="alert-details-tab"
      >
        <alert-details-table :alert="alert" :loading="loading" />
      </gl-tab>
      <gl-tab :title="$options.i18n.timelineTitle" data-testid="timeline-tab">
        <timeline-tab />
      </gl-tab>
    </gl-tabs>
  </div>
</template>

<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import createFlash from '~/flash';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DescriptionComponent from '../description.vue';
import getAlert from './graphql/queries/get_alert.graphql';
import HighlightBar from './highlight_bar.vue';

export default {
  components: {
    AlertDetailsTable,
    DescriptionComponent,
    GlTab,
    GlTabs,
    HighlightBar,
    TimelineTab: () =>
      import('ee_component/issues/show/components/incidents/timeline_events_tab.vue'),
    IncidentMetricTab: () =>
      import('ee_component/issues/show/components/incidents/incident_metric_tab.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['fullPath', 'iid'],
  apollo: {
    alert: {
      query: getAlert,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update(data) {
        return data?.project?.issue?.alertManagementAlert;
      },
      error() {
        createFlash({
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
    incidentTabEnabled() {
      return this.glFeatures.incidentTimelineEvents && this.glFeatures.incidentTimeline;
    },
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    trackPageViews() {
      const { category, action } = trackIncidentDetailsViewsOptions;
      Tracking.event(category, action);
    },
    handleTabChange(tabIndex) {
      const parent = document.querySelector('.js-issue-details');

      if (parent !== null) {
        const itemsToHide = parent.querySelectorAll('.js-issue-widgets');
        const lineSeparator = parent.querySelector('.js-detail-page-description');

        lineSeparator.classList.toggle('gl-border-b-0', tabIndex > 0);

        itemsToHide.forEach(function hide(item) {
          item.classList.toggle('gl-display-none', tabIndex > 0);
        });
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs
      content-class="gl-reset-line-height"
      class="gl-mt-n3"
      data-testid="incident-tabs"
      @input="handleTabChange"
    >
      <gl-tab :title="s__('Incident|Summary')">
        <highlight-bar :alert="alert" />
        <description-component v-bind="$attrs" />
      </gl-tab>
      <incident-metric-tab />
      <gl-tab
        v-if="alert"
        class="alert-management-details"
        :title="s__('Incident|Alert details')"
        data-testid="alert-details-tab"
      >
        <alert-details-table :alert="alert" :loading="loading" />
      </gl-tab>
      <timeline-tab v-if="incidentTabEnabled" data-testid="timeline-events-tab" />
    </gl-tabs>
  </div>
</template>

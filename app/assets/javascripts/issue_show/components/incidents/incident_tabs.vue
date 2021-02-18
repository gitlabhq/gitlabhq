<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import createFlash from '~/flash';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
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
    MetricsTab: () => import('ee_component/issue_show/components/incidents/metrics_tab.vue'),
  },
  inject: ['fullPath', 'iid', 'uploadMetricsFeatureAvailable'],
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
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    trackPageViews() {
      const { category, action } = trackIncidentDetailsViewsOptions;
      Tracking.event(category, action);
    },
  },
};
</script>

<template>
  <div>
    <gl-tabs content-class="gl-reset-line-height" class="gl-mt-n3" data-testid="incident-tabs">
      <gl-tab :title="s__('Incident|Summary')">
        <highlight-bar :alert="alert" />
        <description-component v-bind="$attrs" />
      </gl-tab>
      <metrics-tab v-if="uploadMetricsFeatureAvailable" data-testid="metrics-tab" />
      <gl-tab
        v-if="alert"
        class="alert-management-details"
        :title="s__('Incident|Alert details')"
        data-testid="alert-details-tab"
      >
        <alert-details-table :alert="alert" :loading="loading" />
      </gl-tab>
    </gl-tabs>
  </div>
</template>

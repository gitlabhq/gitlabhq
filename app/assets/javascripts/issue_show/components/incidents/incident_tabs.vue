<script>
import { GlTab, GlTabs } from '@gitlab/ui';
import DescriptionComponent from '../description.vue';
import HighlightBar from './highlight_bar.vue';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import AlertDetailsTable from '~/vue_shared/components/alert_details_table.vue';
import Tracking from '~/tracking';

import getAlert from './graphql/queries/get_alert.graphql';
import { trackIncidentDetailsViewsOptions } from '~/incidents/constants';

export default {
  components: {
    AlertDetailsTable,
    DescriptionComponent,
    GlTab,
    GlTabs,
    HighlightBar,
  },
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
      <gl-tab v-if="alert" class="alert-management-details" :title="s__('Incident|Alert details')">
        <alert-details-table :alert="alert" :loading="loading" />
      </gl-tab>
    </gl-tabs>
  </div>
</template>

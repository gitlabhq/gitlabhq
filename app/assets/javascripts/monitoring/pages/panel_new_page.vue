<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import DashboardPanelBuilder from '../components/dashboard_panel_builder.vue';
import { DASHBOARD_PAGE } from '../router/constants';

export default {
  components: {
    GlButton,
    DashboardPanelBuilder,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  computed: {
    ...mapState('monitoringDashboard', ['panelPreviewYml']),
    dashboardPageLocation() {
      return {
        ...this.$route,
        name: DASHBOARD_PAGE,
      };
    },
  },
  i18n: {
    backToDashboard: s__('Metrics|Back to dashboard'),
  },
};
</script>
<template>
  <div class="gl-mt-5">
    <div class="gl-display-flex gl-align-items-baseline gl-mb-5">
      <gl-button
        v-gl-tooltip
        icon="go-back"
        :to="dashboardPageLocation"
        :aria-label="$options.i18n.backToDashboard"
        :title="$options.i18n.backToDashboard"
        class="gl-mr-5"
      />
      <h1 class="gl-font-size-h1 gl-my-0">{{ s__('Metrics|Add panel') }}</h1>
    </div>
    <dashboard-panel-builder />
  </div>
</template>

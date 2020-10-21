<script>
import { mapState, mapActions } from 'vuex';
import { GlButton, GlLink } from '@gitlab/ui';
import ExternalDashboard from './form_group/external_dashboard.vue';
import DashboardTimezone from './form_group/dashboard_timezone.vue';

export default {
  components: {
    GlButton,
    GlLink,
    ExternalDashboard,
    DashboardTimezone,
  },
  computed: {
    ...mapState(['helpPage']),
    userDashboardUrl: {
      get() {
        return this.externalDashboard.url;
      },
      set(url) {
        this.setExternalDashboardUrl(url);
      },
    },
  },
  methods: {
    ...mapActions(['saveChanges']),
  },
};
</script>

<template>
  <section class="settings no-animate">
    <div class="settings-header">
      <h3 class="js-section-header h4">
        {{ s__('MetricsSettings|Metrics dashboard') }}
      </h3>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{ s__('MetricsSettings|Manage Metrics Dashboard settings.') }}
        <gl-link :href="helpPage">{{ __('Learn more') }}</gl-link>
      </p>
    </div>
    <div class="settings-content">
      <form>
        <dashboard-timezone />
        <external-dashboard />
        <gl-button variant="success" category="primary" @click="saveChanges">
          {{ __('Save Changes') }}
        </gl-button>
      </form>
    </div>
  </section>
</template>

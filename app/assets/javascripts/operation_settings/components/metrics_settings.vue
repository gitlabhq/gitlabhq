<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import DashboardTimezone from './form_group/dashboard_timezone.vue';
import ExternalDashboard from './form_group/external_dashboard.vue';

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
      <h4
        class="js-section-header settings-title js-settings-toggle js-settings-toggle-trigger-only"
      >
        {{ s__('MetricsSettings|Metrics') }}
      </h4>
      <gl-button class="js-settings-toggle">{{ __('Expand') }}</gl-button>
      <p class="js-section-sub-header">
        {{ s__('MetricsSettings|Manage metrics dashboard settings.') }}
        <gl-link :href="helpPage">{{ __('Learn more.') }}</gl-link>
      </p>
    </div>
    <div class="settings-content">
      <form>
        <dashboard-timezone />
        <external-dashboard />
        <gl-button variant="confirm" category="primary" @click="saveChanges">
          {{ __('Save Changes') }}
        </gl-button>
      </form>
    </div>
  </section>
</template>

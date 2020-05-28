<script>
import { mapState, mapActions } from 'vuex';
import { GlDeprecatedButton, GlLink } from '@gitlab/ui';
import ExternalDashboard from './form_group/external_dashboard.vue';

export default {
  components: {
    GlDeprecatedButton,
    GlLink,
    ExternalDashboard,
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
        {{ s__('MetricsSettings|Metrics Dashboard') }}
      </h3>
      <gl-deprecated-button class="js-settings-toggle">{{ __('Expand') }}</gl-deprecated-button>
      <p class="js-section-sub-header">
        {{ s__('MetricsSettings|Manage Metrics Dashboard settings.') }}
        <gl-link :href="helpPage">{{ __('Learn more') }}</gl-link>
      </p>
    </div>
    <div class="settings-content">
      <form>
        <external-dashboard />
        <gl-deprecated-button variant="success" @click="saveChanges">
          {{ __('Save Changes') }}
        </gl-deprecated-button>
      </form>
    </div>
  </section>
</template>

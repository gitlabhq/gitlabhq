<script>
import {
  GlButtonGroup,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlTooltipDirective,
} from '@gitlab/ui';
import Visibility from 'visibilityjs';
import { mapActions } from 'vuex';
import { n__, __, s__ } from '~/locale';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const makeInterval = (length = 0, unit = 's') => {
  const shortLabel = `${length}${unit}`;
  switch (unit) {
    case 'd':
      return {
        interval: length * 24 * 60 * 60 * 1000,
        shortLabel,
        label: n__('%d day', '%d days', length),
      };
    case 'h':
      return {
        interval: length * 60 * 60 * 1000,
        shortLabel,
        label: n__('%d hour', '%d hours', length),
      };
    case 'm':
      return {
        interval: length * 60 * 1000,
        shortLabel,
        label: n__('%d minute', '%d minutes', length),
      };
    case 's':
    default:
      return {
        interval: length * 1000,
        shortLabel,
        label: n__('%d second', '%d seconds', length),
      };
  }
};

export default {
  i18n: {
    refreshDashboard: s__('Metrics|Refresh dashboard'),
  },
  components: {
    GlButtonGroup,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  data() {
    return {
      refreshInterval: null,
      timeoutId: null,
    };
  },
  computed: {
    disableMetricDashboardRefreshRate() {
      // Can refresh rates impact performance?
      // Add "negative" feature flag called `disable_metric_dashboard_refresh_rate`
      // See more at: https://gitlab.com/gitlab-org/gitlab/-/issues/229831
      return this.glFeatures.disableMetricDashboardRefreshRate;
    },
    dropdownText() {
      return this.refreshInterval?.shortLabel ?? __('Off');
    },
  },
  watch: {
    refreshInterval() {
      if (this.refreshInterval !== null) {
        this.startAutoRefresh();
      } else {
        this.stopAutoRefresh();
      }
    },
  },
  destroyed() {
    this.stopAutoRefresh();
  },
  methods: {
    ...mapActions('monitoringDashboard', ['fetchDashboardData']),

    refresh() {
      this.fetchDashboardData();
    },
    startAutoRefresh() {
      const schedule = () => {
        if (this.refreshInterval) {
          this.timeoutId = setTimeout(this.startAutoRefresh, this.refreshInterval.interval);
        }
      };

      this.stopAutoRefresh();

      if (Visibility.hidden()) {
        // Inactive tab? Skip fetch and schedule again
        schedule();
      } else {
        // Active tab! Fetch data and then schedule when settled
        // eslint-disable-next-line promise/catch-or-return
        this.fetchDashboardData().finally(schedule);
      }
    },
    stopAutoRefresh() {
      clearTimeout(this.timeoutId);
      this.timeoutId = null;
    },

    setRefreshInterval(option) {
      this.refreshInterval = option;
    },
    removeRefreshInterval() {
      this.refreshInterval = null;
    },
    isChecked(option) {
      if (this.refreshInterval) {
        return option.interval === this.refreshInterval.interval;
      }
      return false;
    },
  },

  refreshIntervals: [
    makeInterval(5),
    makeInterval(10),
    makeInterval(30),
    makeInterval(5, 'm'),
    makeInterval(30, 'm'),
    makeInterval(1, 'h'),
    makeInterval(2, 'h'),
    makeInterval(12, 'h'),
    makeInterval(1, 'd'),
  ],
};
</script>

<template>
  <gl-button-group>
    <gl-button
      v-gl-tooltip
      class="gl-flex-grow-1"
      variant="default"
      :title="$options.i18n.refreshDashboard"
      :aria-label="$options.i18n.refreshDashboard"
      icon="retry"
      @click="refresh"
    />
    <gl-dropdown
      v-if="!disableMetricDashboardRefreshRate"
      v-gl-tooltip
      :title="s__('Metrics|Set refresh rate')"
      :text="dropdownText"
    >
      <gl-dropdown-item
        :is-check-item="true"
        :is-checked="refreshInterval === null"
        @click="removeRefreshInterval()"
        >{{ __('Off') }}</gl-dropdown-item
      >
      <gl-dropdown-divider />
      <gl-dropdown-item
        v-for="(option, i) in $options.refreshIntervals"
        :key="i"
        :is-check-item="true"
        :is-checked="isChecked(option)"
        @click="setRefreshInterval(option)"
        >{{ option.label }}</gl-dropdown-item
      >
    </gl-dropdown>
  </gl-button-group>
</template>

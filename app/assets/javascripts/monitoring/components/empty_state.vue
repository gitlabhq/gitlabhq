<script>
import { GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';
import { dashboardEmptyStates } from '../constants';

export default {
  components: {
    GlLoadingIcon,
    GlEmptyState,
  },
  props: {
    selectedState: {
      type: String,
      required: true,
      validator: (state) => Object.values(dashboardEmptyStates).includes(state),
    },
    documentationPath: {
      type: String,
      required: true,
    },
    settingsPath: {
      type: String,
      required: false,
      default: '',
    },
    clustersPath: {
      type: String,
      required: false,
      default: '',
    },
    emptyGettingStartedSvgPath: {
      type: String,
      required: true,
    },
    emptyLoadingSvgPath: {
      type: String,
      required: true,
    },
    emptyNoDataSvgPath: {
      type: String,
      required: true,
    },
    emptyNoDataSmallSvgPath: {
      type: String,
      required: true,
    },
    emptyUnableToConnectSvgPath: {
      type: String,
      required: true,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      /**
       * Possible empty states.
       * Keys in each state must match GlEmptyState props
       */
      states: {
        [dashboardEmptyStates.GETTING_STARTED]: {
          svgPath: this.emptyGettingStartedSvgPath,
          title: __('Get started with performance monitoring'),
          description: __(`Stay updated about the performance and health
              of your environment by configuring Prometheus to monitor your deployments.`),
          primaryButtonText: __('Install on clusters'),
          primaryButtonLink: this.clustersPath,
          secondaryButtonText: __('Configure existing installation'),
          secondaryButtonLink: this.settingsPath,
        },
        [dashboardEmptyStates.NO_DATA]: {
          svgPath: this.emptyNoDataSvgPath,
          title: __('No data found'),
          description: __(`You are connected to the Prometheus server, but there is currently
              no data to display.`),
          primaryButtonText: __('Configure Prometheus'),
          primaryButtonLink: this.settingsPath,
          secondaryButtonText: '',
          secondaryButtonLink: '',
        },
        [dashboardEmptyStates.UNABLE_TO_CONNECT]: {
          svgPath: this.emptyUnableToConnectSvgPath,
          title: __('Unable to connect to Prometheus server'),
          description: __(
            'Ensure connectivity is available from the GitLab server to the Prometheus server',
          ),
          primaryButtonText: __('View documentation'),
          primaryButtonLink: this.documentationPath,
          secondaryButtonText: __('Configure Prometheus'),
          secondaryButtonLink: this.settingsPath,
        },
      },
    };
  },
  computed: {
    isLoading() {
      return this.selectedState === dashboardEmptyStates.LOADING;
    },
    currentState() {
      return this.states[this.selectedState];
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="xl" class="gl-my-9" />
    <gl-empty-state v-if="currentState" v-bind="currentState" :compact="compact" />
  </div>
</template>

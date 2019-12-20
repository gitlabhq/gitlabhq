<script>
import { GlEmptyState } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlEmptyState,
  },
  props: {
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
    selectedState: {
      type: String,
      required: true,
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
      states: {
        gettingStarted: {
          svgUrl: this.emptyGettingStartedSvgPath,
          title: __('Get started with performance monitoring'),
          description: __(`Stay updated about the performance and health
              of your environment by configuring Prometheus to monitor your deployments.`),
          buttonText: __('Install on clusters'),
          buttonPath: this.clustersPath,
          secondaryButtonText: __('Configure existing installation'),
          secondaryButtonPath: this.settingsPath,
        },
        loading: {
          svgUrl: this.emptyLoadingSvgPath,
          title: __('Waiting for performance data'),
          description: __(`Creating graphs uses the data from the Prometheus server.
              If this takes a long time, ensure that data is available.`),
          buttonText: __('View documentation'),
          buttonPath: this.documentationPath,
          secondaryButtonText: '',
          secondaryButtonPath: '',
        },
        noData: {
          svgUrl: this.emptyNoDataSvgPath,
          title: __('No data found'),
          description: __(`You are connected to the Prometheus server, but there is currently
              no data to display.`),
          buttonText: __('Configure Prometheus'),
          buttonPath: this.settingsPath,
          secondaryButtonText: '',
          secondaryButtonPath: '',
        },
        unableToConnect: {
          svgUrl: this.emptyUnableToConnectSvgPath,
          title: __('Unable to connect to Prometheus server'),
          description: __(
            'Ensure connectivity is available from the GitLab server to the Prometheus server',
          ),
          buttonText: __('View documentation'),
          buttonPath: this.documentationPath,
          secondaryButtonText: __('Configure Prometheus'),
          secondaryButtonPath: this.settingsPath,
        },
      },
    };
  },
  computed: {
    currentState() {
      return this.states[this.selectedState];
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="currentState.title"
    :description="currentState.description"
    :primary-button-text="currentState.buttonText"
    :primary-button-link="currentState.buttonPath"
    :secondary-button-text="currentState.secondaryButtonText"
    :secondary-button-link="currentState.secondaryButtonPath"
    :svg-path="currentState.svgUrl"
    :compact="compact"
  />
</template>

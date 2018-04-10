<script>
export default {
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
    emptyUnableToConnectSvgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      states: {
        gettingStarted: {
          svgUrl: this.emptyGettingStartedSvgPath,
          title: 'Get started with performance monitoring',
          description: `Stay updated about the performance and health
              of your environment by configuring Prometheus to monitor your deployments.`,
          buttonText: 'Install Prometheus on clusters',
          buttonPath: this.clustersPath,
          secondaryButtonText: 'Configure existing Prometheus',
          secondaryButtonPath: this.settingsPath,
        },
        loading: {
          svgUrl: this.emptyLoadingSvgPath,
          title: 'Waiting for performance data',
          description: `Creating graphs uses the data from the Prometheus server.
              If this takes a long time, ensure that data is available.`,
          buttonText: 'View documentation',
          buttonPath: this.documentationPath,
        },
        noData: {
          svgUrl: this.emptyNoDataSvgPath,
          title: 'No data found',
          description: `You are connected to the Prometheus server, but there is currently
              no data to display.`,
          buttonText: 'Configure Prometheus',
          buttonPath: this.settingsPath,
        },
        unableToConnect: {
          svgUrl: this.emptyUnableToConnectSvgPath,
          title: 'Unable to connect to Prometheus server',
          description: 'Ensure connectivity is available from the GitLab server to the ',
          buttonText: 'View documentation',
          buttonPath: this.documentationPath,
        },
      },
    };
  },
  computed: {
    currentState() {
      return this.states[this.selectedState];
    },
    showButtonDescription() {
      if (this.selectedState === 'unableToConnect') return true;
      return false;
    },
  },
};
</script>

<template>
  <div class="prometheus-state">
    <div class="state-svg svg-content">
      <img :src="currentState.svgUrl" />
    </div>
    <h4 class="state-title">
      {{ currentState.title }}
    </h4>
    <p class="state-description">
      {{ currentState.description }}
      <a
        v-if="showButtonDescription"
        :href="settingsPath"
      >
        Prometheus server
      </a>
    </p>
    <div class="state-button">
      <a
        v-if="currentState.buttonPath"
        class="btn btn-success"
        :href="currentState.buttonPath"
      >
        {{ currentState.buttonText }}
      </a>
    </div>
    <div class="state-button">
      <a
        v-if="currentState.secondaryButtonPath"
        class="btn"
        :href="currentState.secondaryButtonPath"
      >
        {{ currentState.secondaryButtonText }}
      </a>
    </div>
  </div>
</template>

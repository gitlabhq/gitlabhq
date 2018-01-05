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
            buttonText: 'Configure Prometheus',
          },
          loading: {
            svgUrl: this.emptyLoadingSvgPath,
            title: 'Waiting for performance data',
            description: `Creating graphs uses the data from the Prometheus server.
If this takes a long time, ensure that data is available.`,
            buttonText: 'View documentation',
          },
          unableToConnect: {
            svgUrl: this.emptyUnableToConnectSvgPath,
            title: 'Unable to connect to Prometheus server',
            description: 'Ensure connectivity is available from the GitLab server to the ',
            buttonText: 'View documentation',
          },
        },
      };
    },
    computed: {
      currentState() {
        return this.states[this.selectedState];
      },

      buttonPath() {
        if (this.selectedState === 'gettingStarted') {
          return this.settingsPath;
        }
        return this.documentationPath;
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
        class="btn btn-success"
        :href="buttonPath"
      >
        {{ currentState.buttonText }}
      </a>
    </div>
  </div>
</template>

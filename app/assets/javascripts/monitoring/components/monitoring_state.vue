<script>
  import gettingStartedSvg from 'empty_states/monitoring/_getting_started.svg';
  import loadingSvg from 'empty_states/monitoring/_loading.svg';
  import unableToConnectSvg from 'empty_states/monitoring/_unable_to_connect.svg';

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
    },
    data() {
      return {
        states: {
          gettingStarted: {
            svg: gettingStartedSvg,
            title: 'Get started with performance monitoring',
            description: 'Stay updated about the performance and health of your environment by configuring Prometheus to monitor your deployments.',
            buttonText: 'Configure Prometheus',
          },
          loading: {
            svg: loadingSvg,
            title: 'Waiting for performance data',
            description: 'Creating graphs uses the data from the Prometheus server. If this takes a long time, ensure that data is available.',
            buttonText: 'View documentation',
          },
          unableToConnect: {
            svg: unableToConnectSvg,
            title: 'Unable to connect to Prometheus server',
            description: 'Ensure connectivity is available from the GitLab server to the ',
            buttonText: 'View documentation',
          },
        },
      };
    },
    computed: {
      getCurrentState() {
        return this.states[this.selectedState];
      },

      getButtonPath() {
        if (this.selectedState === 'gettingStarted') {
          return this.settingsPath;
        }
        return this.documentationPath;
      },

      getDescriptionText() {
        if (this.selectedState === 'unableToConnect') {
          return `
            ${this.getCurrentState.description}
            <a href="${this.settingsPath}">Prometheus server</a>
          `;
        }
        return this.getCurrentState.description;
      },
    },
  };
</script>
<template>
  <div 
    class="prometheus-state">
    <div 
      class="row">
      <div 
        class="col-md-4 col-md-offset-4 state-svg" v-html="getCurrentState.svg">
      </div>
    </div>
    <div 
      class="row">
      <div 
        class="col-md-6 col-md-offset-3">
        <h4 
          class="text-center state-title">
          {{getCurrentState.title}}
        </h4>
      </div>
    </div>
    <div 
      class="row">
      <div 
        class="col-md-6 col-md-offset-3">
        <div 
          class="description-text text-center state-description" 
          v-html="getDescriptionText">
        </div>
      </div>
    </div>
    <div 
      class="row state-button-section">
      <div 
        class="col-md-4 col-md-offset-4 text-center state-button">
        <a 
          class="btn btn-success" 
          :href="getButtonPath">
            {{getCurrentState.buttonText}}
        </a>
      </div>
    </div>
  </div>
</template>

<script>
  import gettingStartedSvg from 'empty_states/monitoring/_getting_started.svg';
  import loadingSvg from 'empty_states/monitoring/_loading.svg';
  import unableToConnectSvg from 'empty_states/monitoring/_unable_to_connect.svg';

  export default {
    props: {
      isLoading: {
        type: Boolean,
        required: true,
        default: false,
      },
      unableToConnect: {
        type: Boolean,
        required: true,
        default: true,
      },
      gettingStarted: {
        type: Boolean,
        required: true,
        default: false,
      },
    },
    data() {
      return {
        gettingStartedSvg,
        loadingSvg,
        unableToConnectSvg,
      };
    },
    computed: {
      displayCorrespondentSvg() {
        if (this.isLoading) {
          return this.loadingSvg;
        } else if (this.unableToConnect) {
          return this.unableToConnectSvg;
        } else if (this.gettingStarted) {
          return this.gettingStartedSvg;
        }
        return this.loadingSvg;
      },
    },
  };
</script>
<template>
  <div>
    <div class="row">
      <div 
      class="col-md-4 col-md-offset-4 state-svg" 
      v-html="displayCorrespondentSvg">
      </div>
    </div>
    <div class="row">
      <div class="col-md-6 col-md-offset-3">
        <h4 class="text-center state-title">
          Get started with performance monitoring
        </h4>
      </div>
    </div>
  </div>
</template>

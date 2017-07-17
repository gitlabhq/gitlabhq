import Vue from 'vue';
import pipelineDetails from './components/pipeline_details.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-pipeline-details-vue',
  data() {
    const { endpoint, cssClass } = document.querySelector(this.$options.el).dataset;

    return {
      endpoint,
      cssClass,
    };
  },
  components: {
    pipelineDetails,
  },
  render(createElement) {
    return createElement('pipeline-details', {
      props: {
        endpoint: this.endpoint,
        cssClass: this.cssClass,
      },
    });
  },
}));

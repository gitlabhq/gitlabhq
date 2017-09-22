/* global Flash */

import Vue from 'vue';
import Translate from '../vue_shared/translate';
import cycleAnalytics from './components/cycle_analitics_app.vue';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-vue-cycle-analytics',
  data() {
    const dataset = document.querySelector(this.$options.el).dataset;

    return {
      endpoint: dataset.requestPath,
      noData: dataset.cycleAnalyticsNoData,
      helpPath: dataset.helpPath,
      cssClass: dataset.class,
    };
  },
  components: {
    cycleAnalytics,
  },
  render(createElement) {
    return createElement('cycle-analytics', {
      props: {
        endpoint: this.endpoint,
        noData: this.noData,
        helpPath: this.helpPath,
        cssClass: this.cssClass,
      },
    });
  },
}));

import Vue from 'vue';
import performanceBarApp from './components/performance_bar_app.vue';
import PerformanceBarStore from './stores/performance_bar_store';

export default ({ container }) =>
  new Vue({
    el: container,
    components: {
      performanceBarApp,
    },
    data() {
      const performanceBarData = document.querySelector(this.$options.el)
        .dataset;
      const store = new PerformanceBarStore();

      return {
        store,
        env: performanceBarData.env,
        requestId: performanceBarData.requestId,
        peekUrl: performanceBarData.peekUrl,
        profileUrl: performanceBarData.profileUrl,
      };
    },
    render(createElement) {
      return createElement('performance-bar-app', {
        props: {
          store: this.store,
          env: this.env,
          requestId: this.requestId,
          peekUrl: this.peekUrl,
          profileUrl: this.profileUrl,
        },
      });
    },
  });

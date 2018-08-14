import Vue from 'vue';
import Flash from '../flash';
import PerformanceBarService from './services/performance_bar_service';
import PerformanceBarStore from './stores/performance_bar_store';

export default ({ container }) =>
  new Vue({
    el: container,
    components: {
      performanceBarApp: () => import('./components/performance_bar_app.vue'),
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
    mounted() {
      this.interceptor = PerformanceBarService.registerInterceptor(
        this.peekUrl,
        this.loadRequestDetails,
      );

      this.loadRequestDetails(this.requestId, window.location.href);
    },
    beforeDestroy() {
      PerformanceBarService.removeInterceptor(this.interceptor);
    },
    methods: {
      loadRequestDetails(requestId, requestUrl) {
        if (!this.store.canTrackRequest(requestUrl)) {
          return;
        }

        this.store.addRequest(requestId, requestUrl);

        PerformanceBarService.fetchRequestDetails(this.peekUrl, requestId)
          .then(res => {
            this.store.addRequestDetails(requestId, res.data.data);
          })
          .catch(() =>
            Flash(`Error getting performance bar results for ${requestId}`),
          );
      },
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

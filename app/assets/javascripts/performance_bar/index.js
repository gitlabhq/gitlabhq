/* eslint-disable @gitlab/i18n/no-non-i18n-strings */
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';

import PerformanceBarService from './services/performance_bar_service';
import PerformanceBarStore from './stores/performance_bar_store';

export default ({ container }) =>
  new Vue({
    el: container,
    components: {
      PerformanceBarApp: () => import('./components/performance_bar_app.vue'),
    },
    data() {
      const performanceBarData = document.querySelector(this.$options.el).dataset;
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
      addRequestManually(urlOrRequestId) {
        if (urlOrRequestId.startsWith('https://') || urlOrRequestId.startsWith('http://')) {
          // We don't need to do anything with the response, we just
          // want to trace the request.
          axios.get(urlOrRequestId);
        } else {
          this.loadRequestDetails(urlOrRequestId, urlOrRequestId);
        }
      },
      loadRequestDetails(requestId, requestUrl) {
        if (!this.store.canTrackRequest(requestUrl)) {
          return;
        }

        this.store.addRequest(requestId, requestUrl);

        PerformanceBarService.fetchRequestDetails(this.peekUrl, requestId)
          .then(res => {
            this.store.addRequestDetails(requestId, res.data);

            if (this.requestId === requestId) this.collectFrontendPerformanceMetrics();
          })
          .catch(() =>
            // eslint-disable-next-line no-console
            console.warn(`Error getting performance bar results for ${requestId}`),
          );
      },
      collectFrontendPerformanceMetrics() {
        if (performance) {
          const navigationEntries = performance.getEntriesByType('navigation');
          const paintEntries = performance.getEntriesByType('paint');
          const resourceEntries = performance.getEntriesByType('resource');

          let durationString = '';
          if (navigationEntries.length > 0) {
            durationString = `${Math.round(navigationEntries[0].responseEnd)} | `;
            durationString += `${Math.round(paintEntries[1].startTime)} | `;
            durationString += ` ${Math.round(navigationEntries[0].domContentLoadedEventEnd)}`;
          }

          let newEntries = resourceEntries.map(this.transformResourceEntry);

          this.updateFrontendPerformanceMetrics(durationString, newEntries);

          if ('PerformanceObserver' in window) {
            // We start observing for more incoming timings
            const observer = new PerformanceObserver(list => {
              newEntries = newEntries.concat(list.getEntries().map(this.transformResourceEntry));
              this.updateFrontendPerformanceMetrics(durationString, newEntries);
            });

            observer.observe({ entryTypes: ['resource'] });
          }
        }
      },
      updateFrontendPerformanceMetrics(durationString, requestEntries) {
        this.store.setRequestDetailsData(this.requestId, 'total', {
          duration: durationString,
          calls: requestEntries.length,
          details: requestEntries,
        });
      },
      transformResourceEntry(entry) {
        const nf = new Intl.NumberFormat();
        return {
          name: entry.name.replace(document.location.origin, ''),
          duration: Math.round(entry.duration),
          size: entry.transferSize ? `${nf.format(entry.transferSize)} bytes` : 'cached',
        };
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
        on: {
          'add-request': this.addRequestManually,
        },
      });
    },
  });

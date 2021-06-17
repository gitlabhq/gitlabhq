import '../webpack';

import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import Translate from '~/vue_shared/translate';

import initPerformanceBarLog from './performance_bar_log';
import PerformanceBarService from './services/performance_bar_service';
import PerformanceBarStore from './stores/performance_bar_store';

Vue.use(Translate);

const initPerformanceBar = (el) => {
  if (!el) {
    return undefined;
  }
  const performanceBarData = el.dataset;

  return new Vue({
    el,
    components: {
      PerformanceBarApp: () => import('./components/performance_bar_app.vue'),
    },
    data() {
      const store = new PerformanceBarStore();

      return {
        store,
        env: performanceBarData.env,
        requestId: performanceBarData.requestId,
        peekUrl: performanceBarData.peekUrl,
        profileUrl: performanceBarData.profileUrl,
        statsUrl: performanceBarData.statsUrl,
      };
    },
    mounted() {
      PerformanceBarService.registerInterceptor(this.peekUrl, this.loadRequestDetails);

      this.loadRequestDetails(this.requestId, window.location.href);
    },
    beforeDestroy() {
      PerformanceBarService.removeInterceptor();
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
          .then((res) => {
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
          let summary = {};
          if (navigationEntries.length > 0) {
            const backend = Math.round(navigationEntries[0].responseEnd);
            const firstContentfulPaint = Math.round(paintEntries[1].startTime);
            const domContentLoaded = Math.round(navigationEntries[0].domContentLoadedEventEnd);

            summary = {
              [s__('PerformanceBar|Backend')]: backend,
              [s__('PerformanceBar|First Contentful Paint')]: firstContentfulPaint,
              [s__('PerformanceBar|DOM Content Loaded')]: domContentLoaded,
            };

            durationString = `${backend} | ${firstContentfulPaint} | ${domContentLoaded}`;
          }

          let newEntries = resourceEntries.map(this.transformResourceEntry);

          this.updateFrontendPerformanceMetrics(durationString, summary, newEntries);

          if ('PerformanceObserver' in window) {
            // We start observing for more incoming timings
            const observer = new PerformanceObserver((list) => {
              newEntries = newEntries.concat(list.getEntries().map(this.transformResourceEntry));
              this.updateFrontendPerformanceMetrics(durationString, summary, newEntries);
            });

            observer.observe({ entryTypes: ['resource'] });
          }
        }
      },
      updateFrontendPerformanceMetrics(durationString, summary, requestEntries) {
        this.store.setRequestDetailsData(this.requestId, 'total', {
          duration: durationString,
          calls: requestEntries.length,
          details: requestEntries,
          summaryOptions: {
            hideDuration: true,
          },
          summary,
        });
      },
      transformResourceEntry(entry) {
        return {
          start: entry.startTime,
          name: entry.name.replace(document.location.origin, ''),
          duration: Math.round(entry.duration),
          size: entry.transferSize ? numberToHumanSize(entry.transferSize) : 'cached',
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
          statsUrl: this.statsUrl,
        },
        on: {
          'add-request': this.addRequestManually,
        },
      });
    },
  });
};

initPerformanceBar(document.querySelector('#js-peek'));
initPerformanceBarLog();

export default initPerformanceBar;

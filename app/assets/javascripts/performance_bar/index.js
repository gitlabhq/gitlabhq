import { isEmpty } from 'lodash';
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
    name: 'PerformanceBarRoot',
    components: {
      PerformanceBarApp: () => import('./components/performance_bar_app.vue'),
    },
    data() {
      const store = new PerformanceBarStore();

      return {
        store,
        env: performanceBarData.env,
        requestId: performanceBarData.requestId,
        requestMethod: performanceBarData.requestMethod,
        peekUrl: performanceBarData.peekUrl,
        statsUrl: performanceBarData.statsUrl,
      };
    },
    mounted() {
      PerformanceBarService.registerInterceptor(this.peekUrl, this.addRequest);

      this.addRequest(
        this.requestId,
        window.location.href,
        undefined,
        undefined,
        this.requestMethod,
      );
      this.loadRequestDetails(this.requestId);
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
          this.addRequest(urlOrRequestId, urlOrRequestId);
        }
      },
      // eslint-disable-next-line max-params
      addRequest(requestId, requestUrl, operationName, requestParams, methodVerb) {
        if (!this.store.canTrackRequest(requestUrl)) {
          return;
        }

        this.store.addRequest(requestId, requestUrl, operationName, requestParams, methodVerb);
      },
      loadRequestDetails(requestId) {
        const request = this.store.findRequest(requestId);

        if (request && isEmpty(request.details)) {
          return PerformanceBarService.fetchRequestDetails(this.peekUrl, requestId)
            .then((res) => {
              this.store.addRequestDetails(requestId, res.data);
              if (this.requestId === requestId) this.collectFrontendPerformanceMetrics();
            })
            .catch(() =>
              // eslint-disable-next-line no-console
              console.warn(`Error getting performance bar results for ${requestId}`),
            );
        }

        return Promise.resolve();
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
            const firstContentfulPaint = Math.round(
              paintEntries.find((entry) => entry.name === 'first-contentful-paint')?.startTime,
            );
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
          requestMethod: this.requestMethod,
          peekUrl: this.peekUrl,
          statsUrl: this.statsUrl,
        },
        on: {
          'add-request': this.addRequestManually,
          'change-request': this.loadRequestDetails,
        },
      });
    },
  });
};

initPerformanceBar(document.querySelector('#js-peek'));
initPerformanceBarLog();

export default initPerformanceBar;

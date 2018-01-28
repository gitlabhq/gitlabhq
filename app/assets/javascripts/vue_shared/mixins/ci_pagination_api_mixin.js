/**
 * API callbacks for pagination and tabs
 * shared between Pipelines and Environments table.
 *
 * Components need to have `scope`, `page` and `requestData`
 */
import {
  historyPushState,
  buildUrlWithCurrentLocation,
} from '../../lib/utils/common_utils';

export default {
  methods: {
    onChangeTab(scope) {
      this.updateContent({ scope, page: '1' });
    },

    onChangePage(page) {
      /* URLS parameters are strings, we need to parse to match types */
      this.updateContent({ scope: this.scope, page: Number(page).toString() });
    },

    updateInternalState(parameters) {
      // stop polling
      this.poll.stop();

      const queryString = Object.keys(parameters).map((parameter) => {
        const value = parameters[parameter];
        // update internal state for UI
        this[parameter] = value;
        return `${parameter}=${encodeURIComponent(value)}`;
      }).join('&');

      // update polling parameters
      this.requestData = parameters;

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));

      this.isLoading = true;
    },
  },
};

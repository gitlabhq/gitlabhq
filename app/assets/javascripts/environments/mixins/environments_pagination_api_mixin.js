/**
 * API callbacks for pagination and tabs
 *
 * Components need to have `scope`, `page` and `requestData`
 */
import { validateParams } from '~/pipelines/utils';
import { historyPushState, buildUrlWithCurrentLocation } from '../../lib/utils/common_utils';

export default {
  methods: {
    onChangeTab(scope) {
      if (this.scope === scope) {
        return;
      }

      let params = {
        scope,
        page: '1',
        nested: true,
      };

      params = this.onChangeWithFilter(params);

      this.updateContent(params);
    },

    onChangePage(page) {
      /* URLS parameters are strings, we need to parse to match types */
      let params = {
        page: Number(page).toString(),
        nested: true,
      };

      if (this.scope) {
        params.scope = this.scope;
      }

      params = this.onChangeWithFilter(params);

      this.updateContent(params);
    },

    onChangeWithFilter(params) {
      return { ...params, ...validateParams(this.requestData) };
    },

    updateInternalState(parameters) {
      // stop polling
      this.poll.stop();

      const queryString = Object.keys(parameters)
        .map((parameter) => {
          const value = parameters[parameter];
          // update internal state for UI
          this[parameter] = value;
          return `${parameter}=${encodeURIComponent(value)}`;
        })
        .join('&');

      // update polling parameters
      this.requestData = parameters;

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));

      this.isLoading = true;
    },
  },
};

import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

export const useTestCoverage = defineStore('testCoverage', {
  state() {
    return {
      endpoint: null,
      files: {},
      loaded: false,
    };
  },
  actions: {
    fetchCoverage() {
      if (!this.endpoint || this.loaded) return;

      const poll = new Poll({
        resource: {
          getCoverageReports: (endpoint) => axios.get(endpoint),
        },
        data: this.endpoint,
        method: 'getCoverageReports',
        successCallback: ({ status, data }) => {
          if (status !== HTTP_STATUS_OK) return;
          this.files = data?.files || {};
          this.loaded = true;
          poll.stop();
        },
        errorCallback: (error) => {
          poll.stop();
          createAlert({
            message: __('Failed to load test coverage. Try reloading the page.'),
            captureError: true,
            error,
          });
        },
      });

      poll.makeRequest();
    },
  },
  getters: {
    lineHitsForFile() {
      return (filePath) => this.files[filePath] || null;
    },
  },
});

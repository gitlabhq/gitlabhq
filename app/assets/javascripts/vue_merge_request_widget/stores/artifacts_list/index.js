import { defineStore } from 'pinia';
import Visibility from 'visibilityjs';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { s__, n__ } from '~/locale';
import Poll from '~/lib/utils/poll';

let eTagPoll;

export const clearEtagPoll = () => {
  eTagPoll = null;
};

export const stopPolling = () => {
  if (eTagPoll) eTagPoll.stop();
};

export const restartPolling = () => {
  if (eTagPoll) eTagPoll.restart();
};

export const useArtifactsList = defineStore('artifactsList', {
  state() {
    return {
      endpoint: null,
      isLoading: false,
      hasError: false,
      artifacts: [],
    };
  },
  getters: {
    title(state) {
      if (state.isLoading) {
        return s__('BuildArtifacts|Loading artifacts');
      }

      if (state.hasError) {
        return s__('BuildArtifacts|An error occurred while fetching the artifacts');
      }

      return n__('View exposed artifact', 'View %d exposed artifacts', state.artifacts.length);
    },
  },
  actions: {
    setEndpoint(endpoint) {
      this.endpoint = endpoint;
    },
    requestArtifacts() {
      this.isLoading = true;
    },
    receiveArtifactsSuccess(response) {
      // With 204 we keep polling and don't update the state
      if (response.status === HTTP_STATUS_OK) {
        this.hasError = false;
        this.isLoading = false;
        this.artifacts = response.data;
      }
    },
    receiveArtifactsError() {
      this.isLoading = false;
      this.hasError = true;
      this.artifacts = [];
    },
    async fetchArtifacts() {
      this.requestArtifacts();

      eTagPoll = new Poll({
        resource: {
          getArtifacts(endpoint) {
            return axios.get(endpoint);
          },
        },
        data: this.endpoint,
        method: 'getArtifacts',
        successCallback: ({ data, status }) => {
          this.receiveArtifactsSuccess({ data, status });
        },
        errorCallback: () => this.receiveArtifactsError(),
      });

      if (!Visibility.hidden()) {
        eTagPoll.makeRequest();
      } else {
        try {
          const { data, status } = await axios.get(this.endpoint);
          this.receiveArtifactsSuccess({ data, status });
        } catch {
          this.receiveArtifactsError();
        }
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          restartPolling();
        } else {
          stopPolling();
        }
      });
    },
  },
});

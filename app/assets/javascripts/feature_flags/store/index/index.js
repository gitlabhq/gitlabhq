import { defineStore } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';

const updateFlag = (state, flag) => {
  const index = state.featureFlags.findIndex(({ id }) => id === flag.id);
  const copy = [...state.featureFlags];
  copy[index] = flag;
  state.featureFlags = copy;
};

const createPaginationInfo = (headers) => {
  if (Object.keys(headers).length) {
    const normalizedHeaders = normalizeHeaders(headers);
    return parseIntPagination(normalizedHeaders);
  }
  return headers;
};

export const useFeatureFlags = defineStore('featureFlags', {
  state: () => ({
    featureFlags: [],
    alerts: [],
    count: 0,
    pageInfo: {},
    isLoading: true,
    hasError: false,
    endpoint: '',
    rotateEndpoint: '',
    instanceId: '',
    isRotating: false,
    hasRotateError: false,
    options: {},
    projectId: '',
  }),
  actions: {
    setInitialState({ endpoint, projectId, unleashApiInstanceId, rotateInstanceIdPath }) {
      this.endpoint = endpoint;
      this.projectId = projectId;
      this.instanceId = unleashApiInstanceId;
      this.rotateEndpoint = rotateInstanceIdPath;
    },

    setFeatureFlagsOptions(options = {}) {
      this.options = options;
    },

    async fetchFeatureFlags() {
      this.isLoading = true;

      try {
        const response = await axios.get(this.endpoint, { params: this.options });
        const data = response.data || {};
        const headers = response.headers || {};

        this.hasError = false;
        this.featureFlags = data.feature_flags || [];
        const paginationInfo = createPaginationInfo(headers);
        this.count = paginationInfo?.total ?? this.featureFlags.length;
        this.pageInfo = paginationInfo;
      } catch {
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },

    async toggleFeatureFlag(flag) {
      updateFlag(this, flag);

      try {
        const { data } = await axios.put(flag.update_path, {
          operations_feature_flag: flag,
        });
        updateFlag(this, data);
      } catch {
        const current = this.featureFlags.find(({ id }) => flag.id === id);
        updateFlag(this, { ...current, active: !current.active });
      }
    },

    async rotateInstanceId() {
      this.isRotating = true;
      this.hasRotateError = false;

      try {
        const { data = {} } = await axios.post(this.rotateEndpoint);
        this.instanceId = data.token;
      } catch {
        this.hasRotateError = true;
      } finally {
        this.isRotating = false;
      }
    },

    clearAlert(index) {
      this.alerts.splice(index, 1);
    },
  },
});

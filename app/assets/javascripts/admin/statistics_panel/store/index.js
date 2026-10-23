import { defineStore } from 'pinia';
import Api from '~/api';
import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export const useAdminStatistics = defineStore('adminStatistics', {
  state() {
    return {
      error: null,
      isLoading: false,
      statistics: null,
    };
  },
  getters: {
    /**
     * Merges the statisticsLabels with the state's data
     * and returns an array of the following form:
     * [{ key: "forks", label: "Forks", value: 50 }]
     */
    getStatistics() {
      return (labels) =>
        Object.keys(labels).map((key) => ({
          key,
          label: labels[key],
          value: this.statistics && this.statistics[key] ? this.statistics[key] : null,
        }));
    },
  },
  actions: {
    requestStatistics() {
      this.isLoading = true;
    },
    fetchStatistics() {
      this.requestStatistics();

      return Api.adminStatistics()
        .then(({ data }) => {
          this.receiveStatisticsSuccess(convertObjectPropsToCamelCase(data, { deep: true }));
        })
        .catch((error) => this.receiveStatisticsError(error));
    },
    receiveStatisticsSuccess(statistics) {
      this.isLoading = false;
      this.error = null;
      this.statistics = statistics;
    },
    receiveStatisticsError(error) {
      this.isLoading = false;
      this.error = error;
      createAlert({
        message: s__('AdminDashboard|Error loading the statistics. Please try again'),
      });
    },
  },
});

import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import service from '../services/contributors_service';

const showChartDataErrorAlert = () =>
  createAlert({
    message: s__('ContributionAnalytics|An error occurred while loading chart data'),
  });

const incrementDateValue = (dates, date, value = 1) => (dates[date] || 0) + value;

export const useContributors = defineStore('contributors', {
  state() {
    return {
      loading: false,
      statsLoading: false,
      statsLoaded: false,
      chartData: null,
    };
  },
  getters: {
    showChart: (state) => Boolean(!state.loading && state.chartData),
    parsedData: (state) => {
      const byAuthorEmail = {};
      const total = {};
      const additionsTotal = {};
      const deletionsTotal = {};

      (state.chartData || []).forEach(
        ({ date, author_name: name, author_email: email, additions, deletions }) => {
          const normalizedAdditions = additions || 0;
          const normalizedDeletions = deletions || 0;

          total[date] = incrementDateValue(total, date);
          additionsTotal[date] = incrementDateValue(additionsTotal, date, normalizedAdditions);
          deletionsTotal[date] = incrementDateValue(deletionsTotal, date, normalizedDeletions);

          const normalizedEmail = email.toLowerCase();
          const authorData = byAuthorEmail[normalizedEmail];

          if (!authorData) {
            byAuthorEmail[normalizedEmail] = {
              name,
              commits: 1,
              additions: normalizedAdditions,
              deletions: normalizedDeletions,
              dates: {
                [date]: 1,
              },
              additionsByDate: {
                [date]: normalizedAdditions,
              },
              deletionsByDate: {
                [date]: normalizedDeletions,
              },
            };
          } else {
            authorData.commits += 1;
            authorData.additions += normalizedAdditions;
            authorData.deletions += normalizedDeletions;
            authorData.dates[date] = incrementDateValue(authorData.dates, date);
            authorData.additionsByDate[date] = incrementDateValue(
              authorData.additionsByDate,
              date,
              normalizedAdditions,
            );
            authorData.deletionsByDate[date] = incrementDateValue(
              authorData.deletionsByDate,
              date,
              normalizedDeletions,
            );
          }
        },
      );

      return {
        total,
        additionsTotal,
        deletionsTotal,
        byAuthorEmail,
      };
    },
  },
  actions: {
    setLoadingState(value) {
      this.loading = value;
    },
    setStatsLoadingState(value) {
      this.statsLoading = value;
    },
    setChartData(chartData) {
      this.chartData = chartData;
      this.statsLoaded = false;
    },
    setChartStats(chartStats) {
      const statsByCommitId = Object.fromEntries(
        chartStats
          .filter(({ id }) => id)
          .map(({ id, additions, deletions }) => [id, { additions, deletions }]),
      );

      this.chartData = (this.chartData || []).map((commit) => ({
        ...commit,
        ...(statsByCommitId[commit.id] || {}),
      }));
      this.statsLoaded = true;
    },
    fetchChartData(endpoint) {
      this.setLoadingState(true);

      return service
        .fetchChartData(endpoint)
        .then((res) => res.data)
        .then((data) => {
          this.setChartData(data);
          this.setLoadingState(false);
          return true;
        })
        .catch(() => {
          this.setLoadingState(false);
          showChartDataErrorAlert();

          return false;
        });
    },
    fetchChartStats(endpoint) {
      if (this.statsLoaded || this.statsLoading) {
        return Promise.resolve(true);
      }

      this.setStatsLoadingState(true);

      return service
        .fetchChartData(endpoint, { with_stats: true })
        .then((res) => res.data)
        .then((data) => {
          this.setChartStats(data);
          this.setStatsLoadingState(false);
          return true;
        })
        .catch(() => {
          this.setStatsLoadingState(false);
          showChartDataErrorAlert();

          return false;
        });
    },
  },
});

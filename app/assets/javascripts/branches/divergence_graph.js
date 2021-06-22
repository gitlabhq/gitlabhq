import Vue from 'vue';
import createFlash from '~/flash';
import axios from '../lib/utils/axios_utils';
import { __ } from '../locale';
import DivergenceGraph from './components/divergence_graph.vue';

export function createGraphVueApp(el, data, maxCommits, defaultBranch) {
  return new Vue({
    el,
    render(h) {
      return h(DivergenceGraph, {
        props: {
          defaultBranch,
          distance: data.distance ? parseInt(data.distance, 10) : null,
          aheadCount: parseInt(data.ahead, 10),
          behindCount: parseInt(data.behind, 10),
          maxCommits,
        },
      });
    },
  });
}

export default (endpoint, defaultBranch) => {
  const names = [...document.querySelectorAll('.js-branch-item')].map(
    ({ dataset }) => dataset.name,
  );

  if (names.length === 0) {
    return true;
  }

  return axios
    .get(endpoint, {
      params: { names },
    })
    .then(({ data }) => {
      const maxCommits = Object.entries(data).reduce((acc, [, val]) => {
        const max = Math.max(...Object.values(val));
        return max > acc ? max : acc;
      }, 100);

      Object.entries(data).forEach(([branchName, val]) => {
        const el = document.querySelector(
          `[data-name="${branchName}"] .js-branch-divergence-graph`,
        );

        if (!el) return;

        createGraphVueApp(el, val, maxCommits, defaultBranch);
      });
    })
    .catch(() =>
      createFlash({
        message: __('Error fetching diverging counts for branches. Please try again.'),
      }),
    );
};

import Vue from 'vue';
import DivergenceGraph from './components/divergence_graph.vue';

export default () => {
  document.querySelectorAll('.js-branch-divergence-graph').forEach(el => {
    const { distance, aheadCount, behindCount, defaultBranch, maxCommits } = el.dataset;

    return new Vue({
      el,
      render(h) {
        return h(DivergenceGraph, {
          props: {
            defaultBranch,
            distance: distance ? parseInt(distance, 10) : null,
            aheadCount: parseInt(aheadCount, 10),
            behindCount: parseInt(behindCount, 10),
            maxCommits: parseInt(maxCommits, 10),
          },
        });
      },
    });
  });
};

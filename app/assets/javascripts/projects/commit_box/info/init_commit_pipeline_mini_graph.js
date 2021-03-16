import Vue from 'vue';

export const initCommitPipelineMiniGraph = async (selector = '.js-commit-pipeline-mini-graph') => {
  const el = document.querySelector(selector);
  if (!el) {
    return;
  }

  // Some commits have no pipeline, code splitting to load the pipeline optionally
  const { stages } = el.dataset;
  const { default: PipelineMiniGraph } = await import(
    /* webpackChunkName: 'pipelineMiniGraph' */ '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue'
  );

  // eslint-disable-next-line no-new
  new Vue({
    el,
    render(createElement) {
      return createElement(PipelineMiniGraph, {
        props: {
          stages: JSON.parse(stages),
        },
      });
    },
  });
};

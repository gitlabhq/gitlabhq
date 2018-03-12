import $ from 'jquery';
import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';
import initPipelines from '~/commit/pipelines/pipelines_bundle';

document.addEventListener('DOMContentLoaded', () => {
  new MiniPipelineGraph({
    container: '.js-commit-pipeline-graph',
  }).bindEvents();
  $('.commit-info.branches').load(document.querySelector('.js-commit-box').dataset.commitPath);
  initPipelines();
});

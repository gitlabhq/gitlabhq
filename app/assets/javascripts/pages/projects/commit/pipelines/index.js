import MiniPipelineGraph from '~/mini_pipeline_graph_dropdown';

export default () => {
  new MiniPipelineGraph({
    container: '.js-commit-pipeline-graph',
  }).bindEvents();
  $('.commit-info.branches').load(document.querySelector('.js-commit-box').dataset.commitPath);
};

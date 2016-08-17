(function() {
  function toggleGraph() {
    const $pipelineBtn = $(this).closest('.toggle-pipeline-btn');
    const $pipelineGraph = $(this).closest('.row-content-block').next('.pipeline-graph');
    const $btnText = $(this).find('.toggle-btn-text');

    $($pipelineBtn).add($pipelineGraph).toggleClass('graph-collapsed');

    const graphCollapsed = $pipelineGraph.hasClass('graph-collapsed');

    graphCollapsed ? $btnText.text('Expand') : $btnText.text('Hide')
  }

  $(document).on('click', '.toggle-pipeline-btn', toggleGraph);
})();

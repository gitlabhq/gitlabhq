(function() {

  function addMarginToBuild () {
    const $secondChildBuildNode = $('.build:nth-child(2)');
    const $firstChildBuildNode = $secondChildBuildNode.prev('.build');
    // const $previousBuildColumn = $secondChildBuildNode.closest('.stage-column').prev('.stage-column');
    if ($secondChildBuildNode.length) {
      $secondChildBuildNode.closest('.stage-column').addClass('left-margin');
      $firstChildBuildNode.addClass('left-connector');
    }
  }

  function toggleGraph() {
    const $pipelineBtn = $(this).closest('.toggle-pipeline-btn');
    const $pipelineGraph = $(this).closest('.row-content-block').next('.pipeline-graph');
    const $btnText = $(this).find('.toggle-btn-text');
    const $icon = $(this).find('.fa');

    $($pipelineBtn).add($pipelineGraph).toggleClass('graph-collapsed');

    const graphCollapsed = $pipelineGraph.hasClass('graph-collapsed');
    const expandIcon = 'fa-caret-down';
    const hideIcon = 'fa-caret-up';

    if(graphCollapsed) {
      $btnText.text('Expand');
      $icon.removeClass(hideIcon).addClass(expandIcon);
    } else {
      $btnText.text('Hide');
      $icon.removeClass(expandIcon).addClass(hideIcon);
    }
  }

  $(document).on('click', '.toggle-pipeline-btn', toggleGraph);
  $(document).on('ready', addMarginToBuild);
})();

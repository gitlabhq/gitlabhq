(function() {

  function addMarginToBuild () {
    const $secondChild = $('.build:nth-child(2)');
    if ($secondChild.length) {
      $secondChild.closest('.stage-column').addClass('left-margin');
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

((global) => {

  class Pipelines {
    constructor() {
      $(document).off('click', '.toggle-pipeline-btn').on('click', '.toggle-pipeline-btn', this.toggleGraph);
      this.addMarginToBuildColumns();
    }

    toggleGraph() {
      const $pipelineBtn = $(this).closest('.toggle-pipeline-btn');
      const $pipelineGraph = $(this).closest('.row-content-block').next('.pipeline-graph');
      const $btnText = $(this).find('.toggle-btn-text');
      const graphCollapsed = $pipelineGraph.hasClass('graph-collapsed');

      $($pipelineBtn).add($pipelineGraph).toggleClass('graph-collapsed');


      graphCollapsed ? $btnText.text('Hide') : $btnText.text('Expand')
    }

    addMarginToBuildColumns() {
      const $secondChildBuildNode = $('.build:nth-child(2)');
      if ($secondChildBuildNode.length) {
        const $firstChildBuildNode = $secondChildBuildNode.prev('.build');
        const $multiBuildColumn = $secondChildBuildNode.closest('.stage-column');
        const $previousColumn = $multiBuildColumn.prev('.stage-column');
        $multiBuildColumn.addClass('left-margin');
        $firstChildBuildNode.addClass('left-connector');
        $previousColumn.each(function() {
          $this = $(this);
          if ($('.build', $this).length === 1) $this.addClass('no-margin');
        });
      }
      $('.pipeline-graph').removeClass('hidden');
    }
  }

  global.Pipelines = Pipelines;

})(window.gl || (window.gl = {}));

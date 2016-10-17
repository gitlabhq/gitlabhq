((global) => {

  class Pipelines {
    constructor() {
      this.initGraphToggle();
      this.addMarginToBuildColumns();
    }

    initGraphToggle() {
      this.toggleButton = document.querySelector('.toggle-pipeline-btn');
      this.toggleButtonText = this.toggleButton.querySelector('.toggle-btn-text');
      this.pipelineGraph = document.querySelector('.pipeline-graph');
      this.toggleButton.addEventListener('click', this.toggleGraph.bind(this));
    }

    toggleGraph() {
      const graphCollapsed = this.pipelineGraph.classList.contains('graph-collapsed');
      this.toggleButton.classList.toggle('graph-collapsed');
      this.pipelineGraph.classList.toggle('graph-collapsed');
      graphCollapsed ? this.toggleButtonText.textContent = 'Hide' : this.toggleButtonText.textContent = 'Expand';
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
      this.pipelineGraph.classList.remove('hidden');
    }
  }

  global.Pipelines = Pipelines;

})(window.gl || (window.gl = {}));

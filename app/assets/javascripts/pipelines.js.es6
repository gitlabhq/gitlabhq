/* eslint-disable */
((global) => {

  class Pipelines {
    constructor() {
      this.initGraphToggle();
      this.addMarginToBuildColumns();
    }

    initGraphToggle() {
      this.pipelineGraph = document.querySelector('.pipeline-graph');
      this.toggleButton = document.querySelector('.toggle-pipeline-btn');
      this.toggleButtonText = this.toggleButton.querySelector('.toggle-btn-text');
      this.toggleButton.addEventListener('click', this.toggleGraph.bind(this));
    }

    toggleGraph() {
      const graphCollapsed = this.pipelineGraph.classList.contains('graph-collapsed');
      this.toggleButton.classList.toggle('graph-collapsed');
      this.pipelineGraph.classList.toggle('graph-collapsed');
      this.toggleButtonText.textContent = graphCollapsed ? 'Hide' : 'Expand';
    }

    addMarginToBuildColumns() {
      const secondChildBuildNodes = this.pipelineGraph.querySelectorAll('.build:nth-child(2)');
      for (buildNodeIndex in secondChildBuildNodes) {
        const buildNode = secondChildBuildNodes[buildNodeIndex];
        const firstChildBuildNode = buildNode.previousElementSibling;
        if (!firstChildBuildNode || !firstChildBuildNode.matches('.build')) continue;
        const multiBuildColumn = buildNode.closest('.stage-column');
        const previousColumn = multiBuildColumn.previousElementSibling;
        if (!previousColumn || !previousColumn.matches('.stage-column')) continue;
        multiBuildColumn.classList.add('left-margin');
        firstChildBuildNode.classList.add('left-connector');
        const columnBuilds = previousColumn.querySelectorAll('.build');
        if (columnBuilds.length === 1) previousColumn.classList.add('no-margin');
      }
      this.pipelineGraph.classList.remove('hidden');
    }
  }

  global.Pipelines = Pipelines;

})(window.gl || (window.gl = {}));

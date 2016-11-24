/* eslint-disable */
((global) => {

  class Pipelines {
    constructor() {
      this.addMarginToBuildColumns();
    }

    addMarginToBuildColumns() {
      this.pipelineGraph = document.querySelector('.pipeline-graph');
      const secondChildBuildNodes = document.querySelector('.pipeline-graph').querySelectorAll('.build:nth-child(2)');
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

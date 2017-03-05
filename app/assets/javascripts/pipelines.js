/* eslint-disable no-new, guard-for-in, no-restricted-syntax, no-continue, no-param-reassign, max-len */

require('./lib/utils/bootstrap_linked_tabs');

((global) => {
  class Pipelines {
    constructor(options = {}) {
      if (options.initTabs && options.tabsOptions) {
        new global.LinkedTabs(options.tabsOptions);
      }

      this.addMarginToBuildColumns();
    }

    addMarginToBuildColumns() {
      this.pipelineGraph = document.querySelector('.js-pipeline-graph');

      const secondChildBuildNodes = this.pipelineGraph.querySelectorAll('.build:nth-child(2)');

      for (const buildNodeIndex in secondChildBuildNodes) {
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

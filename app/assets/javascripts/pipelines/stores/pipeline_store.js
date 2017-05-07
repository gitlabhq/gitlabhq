export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.graph = [];
  }

  storeGraph(graph = []) {
    this.state.graph = graph;
  }
}

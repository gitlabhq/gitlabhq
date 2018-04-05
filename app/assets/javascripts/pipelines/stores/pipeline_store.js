export default class PipelineStore {
  constructor() {
    this.state = {};
    this.state.pipeline = {};
  }

  storePipeline(pipeline = {}) {
    this.state.pipeline = pipeline;
  }
}

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.pipeline = {};
    this.state.log = [];
    this.state.job = {};
  }

  storePipeline(pipeline = {}) {
    this.state.pipeline = pipeline;
  }

  storeLog(log = []) {
    this.state.log = log;
  }
}

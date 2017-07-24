export default class PipelineStore {
  constructor() {
    this.state = {
      pipeline: {},
      log: [],
      job: {},
    };
  }

  storePipeline(pipeline = {}) {
    this.state.pipeline = pipeline;
  }

  storeLog(log = []) {
    this.state.log = log;
  }

  storeJob(job = {}) {
    this.state.job = job;
  }
}

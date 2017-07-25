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

  addLogLine(line) {
    this.state.log.push(line);
  }

  storeJob(job = {}) {
    this.state.job = job;
  }

  resetJob() {
    this.state.job = {};
    this.state.log = [];
  }
}

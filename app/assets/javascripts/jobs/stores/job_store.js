export default class JobStore {
  constructor() {
    this.state = {
      job: {},
    };
  }

  storeJob(job = {}) {
    this.state.job = job;
  }
}

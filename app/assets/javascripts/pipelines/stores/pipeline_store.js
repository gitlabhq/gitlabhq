import { addRemainingTime } from '../helpers';

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.pipeline = {};
  }

  storePipeline(pipeline = {}) {
    this.state.pipeline = pipeline;
    this.updateDelayedJobs();
  }

  updateDelayedJobs() {
    const { details } = this.state.pipeline;
    if (!details || !details.stages) {
      return;
    }

    details.stages = details.stages.map(stage => ({
      ...stage,
      groups: stage.groups.map(addRemainingTime),
    }));

    window.setTimeout(() => this.updateDelayedJobs(), 1000);
  }
}

const mockTriggerers = [
  { id: 111, path: 'hello/world/tho', project: { name: 'GitLab Shell' }, details: { status: { icon: 'icon_status_pending', group: 'pending', label: 'pending' } } },
];

const mockTriggereds = [
  { id: 111, path: 'hello/world/tho', project: { name: 'GitLab EE' }, details: { status: { icon: 'icon_status_failed', group: 'failed', label: 'failed' } } },
  { id: 111, path: 'hello/world/tho', project: { name: 'Gitaly' }, details: { status: { icon: 'icon_status_pending', group: 'pending', label: 'pending' } } },
  { id: 111, path: 'hello/world/tho', project: { name: 'GitHub' }, details: { status: { icon: 'icon_status_success', group: 'success', label: 'success' } } },
];

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.pipeline = {};
    this.state.triggered = [];
    this.state.triggeredBy = [];
  }

  storePipeline(pipeline = {}) {
    // single job in first stage
    pipeline.details.stages[3].groups = [pipeline.details.stages[0].groups[0]];

    // multiple jobs in last stage
    // pipeline.details.stages[3].groups.push(pipeline.details.stages[0].groups[0]);
    this.state.pipeline = pipeline;
    this.state.triggeredBy = mockTriggerers;

    // single triggered
    // this.state.triggered = [mockTriggereds[0]];
    this.state.triggered = mockTriggereds;
  }
}

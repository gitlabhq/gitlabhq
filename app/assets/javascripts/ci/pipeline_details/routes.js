import PipelineGraphWrapper from './graph/graph_component_wrapper.vue';
import Dag from './dag/dag.vue';
import FailedJobsApp from './jobs/failed_jobs_app.vue';
import JobsApp from './jobs/jobs_app.vue';
import TestReports from './test_reports/test_reports.vue';
import {
  pipelineTabName,
  needsTabName,
  jobsTabName,
  failedJobsTabName,
  testReportTabName,
} from './constants';

export const routes = [
  { name: pipelineTabName, path: '/', component: PipelineGraphWrapper },
  { name: needsTabName, path: '/dag', component: Dag },
  { name: jobsTabName, path: '/builds', component: JobsApp },
  { name: failedJobsTabName, path: '/failures', component: FailedJobsApp },
  { name: testReportTabName, path: '/test_report', component: TestReports },
];

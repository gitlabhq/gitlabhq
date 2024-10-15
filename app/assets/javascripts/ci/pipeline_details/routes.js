import PipelineGraphWrapper from './graph/graph_component_wrapper.vue';
import FailedJobsApp from './jobs/failed_jobs_app.vue';
import JobsApp from './jobs/jobs_app.vue';
import TestReports from './test_reports/test_reports.vue';
import ManualVariables from './manual_variables/manual_variables.vue';
import {
  pipelineTabName,
  jobsTabName,
  failedJobsTabName,
  testReportTabName,
  manualVariablesTabName,
} from './constants';

export const routes = [
  { name: pipelineTabName, path: '/', component: PipelineGraphWrapper },
  { name: jobsTabName, path: '/builds', component: JobsApp },
  { name: failedJobsTabName, path: '/failures', component: FailedJobsApp },
  { name: testReportTabName, path: '/test_report', component: TestReports },
  { name: manualVariablesTabName, path: '/manual_variables', component: ManualVariables },
];

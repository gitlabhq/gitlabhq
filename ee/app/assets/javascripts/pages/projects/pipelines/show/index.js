import initPipelineDetails from '~/pipelines/pipeline_details_bundle';
import initPipelines from '~/pages/projects/pipelines/init_pipelines';
import initSecurityReport from './security_report';
import initLicenseReport from './license_report';

document.addEventListener('DOMContentLoaded', () => {
  initPipelines();
  initPipelineDetails();
  initSecurityReport();
  initLicenseReport();
});

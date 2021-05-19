import { capitalize } from 'lodash';
import {
  securityReportTypeEnumToReportType,
  REPORT_FILE_TYPES,
} from 'ee_else_ce/vue_shared/security_reports/constants';

const addReportTypeIfExists = (acc, reportTypes, reportType, getName, downloadPath) => {
  if (reportTypes && reportTypes.includes(reportType)) {
    acc.push({
      reportType,
      name: getName(reportType),
      path: downloadPath,
    });
  }
};

const extractSecurityReportArtifacts = (reportTypes, jobs) => {
  return jobs.reduce((acc, job) => {
    const artifacts = job.artifacts?.nodes ?? [];

    artifacts.forEach(({ downloadPath, fileType }) => {
      addReportTypeIfExists(
        acc,
        reportTypes,
        securityReportTypeEnumToReportType[fileType],
        () => job.name,
        downloadPath,
      );

      addReportTypeIfExists(
        acc,
        reportTypes,
        REPORT_FILE_TYPES[fileType],
        (reportType) => `${job.name} ${capitalize(reportType)}`,
        downloadPath,
      );
    });

    return acc;
  }, []);
};

export const extractSecurityReportArtifactsFromPipeline = (reportTypes, data) => {
  const jobs = data.project?.pipeline?.jobs?.nodes ?? [];
  return extractSecurityReportArtifacts(reportTypes, jobs);
};

export const extractSecurityReportArtifactsFromMergeRequest = (reportTypes, data) => {
  const jobs = data.project?.mergeRequest?.headPipeline?.jobs?.nodes ?? [];
  return extractSecurityReportArtifacts(reportTypes, jobs);
};

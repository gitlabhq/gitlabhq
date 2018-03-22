import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import {
  parseCodeclimateMetrics,
  filterByKey,
  setSastContainerReport,
  setSastReport,
  setDastReport,
} from '../../vue_shared/security_reports/helpers/utils';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);

    const blobPath = data.blob_path || {};
    this.headBlobPath = blobPath.head_path || '';
    this.baseBlobPath = blobPath.base_path || '';

    this.initCodeclimate(data);
    this.initPerformanceReport(data);
    this.initSecurityReport(data);
    this.initDockerReport(data);
    this.initDastReport(data);
  }

  setData(data) {
    this.initGeo(data);
    this.initSquashBeforeMerge(data);
    this.initApprovals(data);

    super.setData(data);
  }

  initSquashBeforeMerge(data) {
    this.squashBeforeMergeHelpPath = this.squashBeforeMergeHelpPath
      || data.squash_before_merge_help_path;
    this.enableSquashBeforeMerge = this.enableSquashBeforeMerge
      || data.enable_squash_before_merge;
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals(data) {
    this.isApproved = this.isApproved || false;
    this.approvals = this.approvals || null;
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = data.approvalsRequired || Boolean(this.approvalsPath);
  }

  setApprovals(data) {
    this.approvals = data;
    this.approvalsLeft = !!data.approvals_left;
    this.isApproved = !this.approvalsLeft || false;
    this.preventMerge = this.approvalsRequired && this.approvalsLeft;
  }

  initCodeclimate(data) {
    this.codeclimate = data.codeclimate;
    this.codeclimateMetrics = {
      newIssues: [],
      resolvedIssues: [],
    };
  }

  initPerformanceReport(data) {
    this.performance = data.performance;
    this.performanceMetrics = {
      improved: [],
      degraded: [],
    };
  }

  initSecurityReport(data) {
    this.sast = data.sast;
    this.securityReport = {
      newIssues: [],
      resolvedIssues: [],
      allIssues: [],
    };
  }

  initDockerReport(data) {
    this.sastContainer = data.sast_container;
    this.dockerReport = {
      approved: [],
      unapproved: [],
      vulnerabilities: [],
    };
  }

  initDastReport(data) {
    this.dast = data.dast;
    this.dastReport = [];
  }

  setSecurityReport(data) {
    const report = setSastReport(data);
    this.securityReport.newIssues = report.newIssues;
    this.securityReport.resolvedIssues = report.resolvedIssues;
    this.securityReport.allIssues = report.allIssues;
  }

  setDockerReport(data = {}) {
    const report = setSastContainerReport(data);
    this.dockerReport.approved = report.approved;
    this.dockerReport.unapproved = report.unapproved;
    this.dockerReport.vulnerabilities = report.vulnerabilities;
  }

  setDastReport(data) {
    this.dastReport = setDastReport(data);
  }

  compareCodeclimateMetrics(headIssues, baseIssues, headBlobPath, baseBlobPath) {
    const parsedHeadIssues = parseCodeclimateMetrics(headIssues, headBlobPath);
    const parsedBaseIssues = parseCodeclimateMetrics(baseIssues, baseBlobPath);

    this.codeclimateMetrics.newIssues = filterByKey(
      parsedHeadIssues,
      parsedBaseIssues,
      'fingerprint',
    );
    this.codeclimateMetrics.resolvedIssues = filterByKey(
      parsedBaseIssues,
      parsedHeadIssues,
      'fingerprint',
    );
  }

  comparePerformanceMetrics(headMetrics, baseMetrics) {
    const headMetricsIndexed = MergeRequestStore.normalizePerformanceMetrics(headMetrics);
    const baseMetricsIndexed = MergeRequestStore.normalizePerformanceMetrics(baseMetrics);

    const improved = [];
    const degraded = [];
    const neutral = [];

    Object.keys(headMetricsIndexed).forEach((subject) => {
      const subjectMetrics = headMetricsIndexed[subject];
      Object.keys(subjectMetrics).forEach((metric) => {
        const headMetricData = subjectMetrics[metric];

        if (baseMetricsIndexed[subject] && baseMetricsIndexed[subject][metric]) {
          const baseMetricData = baseMetricsIndexed[subject][metric];
          const metricDirection = 'desiredSize' in headMetricData && headMetricData.desiredSize === 'smaller' ? -1 : 1;
          const metricData = {
            name: metric,
            path: subject,
            score: headMetricData.value,
            delta: headMetricData.value - baseMetricData.value,
          };

          if (metricData.delta === 0) {
            neutral.push(metricData);
          } else if (metricData.delta * metricDirection > 0) {
            improved.push(metricData);
          } else {
            degraded.push(metricData);
          }
        } else {
          neutral.push({
            name: metric,
            path: subject,
            score: headMetricData.value,
          });
        }
      });
    });

    this.performanceMetrics = { improved, degraded, neutral };
  }

  // normalize performance metrics by indexing on performance subject and metric name
  static normalizePerformanceMetrics(performanceData) {
    const indexedSubjects = {};
    performanceData.forEach(({ subject, metrics }) => {
      const indexedMetrics = {};
      metrics.forEach(({ name, ...data }) => {
        indexedMetrics[name] = data;
      });
      indexedSubjects[subject] = indexedMetrics;
    });

    return indexedSubjects;
  }
}

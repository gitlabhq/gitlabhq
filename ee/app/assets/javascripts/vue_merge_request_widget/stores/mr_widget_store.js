import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';
import { stripHtml } from '~/lib/utils/text_utility';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);
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
    this.securityReport = [];
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

  setSecurityReport(issues, path) {
    this.securityReport = MergeRequestStore.parseIssues(issues, path);
  }

  setDockerReport(data = {}) {
    const parsedVulnerabilities = MergeRequestStore
      .parseDockerVulnerabilities(data.vulnerabilities);

    this.dockerReport.vulnerabilities = parsedVulnerabilities || [];

    // There is a typo in the original repo:
    // https://github.com/arminc/clair-scanner/pull/39/files
    // Fix this when the above PR is accepted
    const unapproved = data.unapproved || data.unaproved || [];

    // Approved can be calculated by subtracting unapproved from vulnerabilities.
    this.dockerReport.approved = parsedVulnerabilities
      .filter(item => !unapproved.find(el => el === item.vulnerability)) || [];

    this.dockerReport.unapproved = parsedVulnerabilities
      .filter(item => unapproved.find(el => el === item.vulnerability)) || [];
  }
  /**
   * Dast Report sends some keys in HTML, we need to strip the `<p>` tags.
   * This should be moved to the backend.
   *
   * @param {Array} data
   * @returns {Array}
   */
  setDastReport(data) {
    this.dastReport = data.site.alerts.map(alert => ({
      name: alert.name,
      parsedDescription: stripHtml(alert.desc, ' '),
      priority: alert.riskdesc,
      ...alert,
    }));
  }

  static parseDockerVulnerabilities(data) {
    return data.map(el => ({
      name: el.vulnerability,
      priority: el.severity,
      path: el.namespace,
      // external link to provide better description
      nameLink: `https://cve.mitre.org/cgi-bin/cvename.cgi?name=${el.vulnerability}`,
      ...el,
    }));
  }

  compareCodeclimateMetrics(headIssues, baseIssues, headBlobPath, baseBlobPath) {
    const parsedHeadIssues = MergeRequestStore.parseIssues(headIssues, headBlobPath);
    const parsedBaseIssues = MergeRequestStore.parseIssues(baseIssues, baseBlobPath);

    this.codeclimateMetrics.newIssues = MergeRequestStore.filterByFingerprint(
      parsedHeadIssues,
      parsedBaseIssues,
    );
    this.codeclimateMetrics.resolvedIssues = MergeRequestStore.filterByFingerprint(
      parsedBaseIssues,
      parsedHeadIssues,
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
          const metricData = {
            name: metric,
            path: subject,
            score: headMetricData.value,
            delta: headMetricData.value - baseMetricData.value,
          };

          if (headMetricData.value > baseMetricData.value) {
            improved.push(metricData);
          } else if (headMetricData.value < baseMetricData.value) {
            degraded.push(metricData);
          } else {
            neutral.push(metricData);
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

  /**
   * In order to reuse the same component we need
   * to set both codequality and security issues to have the same data structure:
   * [
   *   {
   *     name: String,
   *     priority: String,
   *     fingerprint: String,
   *     path: String,
   *     line: Number,
   *     urlPath: String
   *   }
   * ]
   * @param {array} issues
   * @return {array}
   */
  static parseIssues(issues, path) {
    return issues.map((issue) => {
      const parsedIssue = {
        name: issue.check_name || issue.message,
        ...issue,
      };

      // code quality
      if (issue.location) {
        let parseCodeQualityUrl;

        if (issue.location.path) {
          parseCodeQualityUrl = `${path}/${issue.location.path}`;
          parsedIssue.path = issue.location.path;
        }

        if (issue.location.lines && issue.location.lines.begin) {
          parsedIssue.line = issue.location.lines.begin;
          parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
        }

        parsedIssue.urlPath = parseCodeQualityUrl;

      // security
      } else if (issue.file) {
        let parsedSecurityUrl = `${path}/${issue.file}`;
        parsedIssue.path = issue.file;

        if (issue.line) {
          parsedSecurityUrl += `#L${issue.line}`;
        }
        parsedIssue.urlPath = parsedSecurityUrl;
      }

      return parsedIssue;
    });
  }

  static filterByFingerprint(firstArray, secondArray) {
    return firstArray.filter(item => !secondArray.find(el => el.fingerprint === item.fingerprint));
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

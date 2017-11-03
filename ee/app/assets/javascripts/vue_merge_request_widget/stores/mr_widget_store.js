import CEMergeRequestStore from '~/vue_merge_request_widget/stores/mr_widget_store';

export default class MergeRequestStore extends CEMergeRequestStore {
  constructor(data) {
    super(data);
    this.initCodeclimate(data);
    this.initSecurityReport(data);
  }

  setData(data) {
    this.initGeo(data);
    this.initSquashBeforeMerge(data);
    this.initRebase(data);
    this.initApprovals(data);

    super.setData(data);
  }

  initSquashBeforeMerge(data) {
    this.squashBeforeMergeHelpPath = this.squashBeforeMergeHelpPath
      || data.squash_before_merge_help_path;
    this.enableSquashBeforeMerge = this.enableSquashBeforeMerge
      || data.enable_squash_before_merge;
  }

  initRebase(data) {
    this.canPushToSourceBranch = data.can_push_to_source_branch;
    this.rebaseInProgress = data.rebase_in_progress;
    this.approvalsLeft = !data.approved;
    this.rebasePath = data.rebase_path;
  }

  initGeo(data) {
    this.isGeoSecondaryNode = this.isGeoSecondaryNode || data.is_geo_secondary_node;
    this.geoSecondaryHelpPath = this.geoSecondaryHelpPath || data.geo_secondary_help_path;
  }

  initApprovals(data) {
    this.isApproved = this.isApproved || false;
    this.approvals = this.approvals || null;
    this.approvalsPath = data.approvals_path || this.approvalsPath;
    this.approvalsRequired = Boolean(this.approvalsPath);
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

  initSecurityReport(data) {
    this.security = data.security;
    this.securityReport = [];
  }

  setSecurityReport(issues) {
    this.securityReport = MergeRequestStore.parseIssues(issues);
  }
  // TODO: get changes from codequality MR
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
          parsedIssue.urlPath = parseCodeQualityUrl += `#L${issue.location.lines.begin}`;
        }
      } else {
        // security
        let parsedSecurityUrl;
        if (issue.file) {
          parsedSecurityUrl = `${path}/${issue.file}`;
          parsedIssue.path = issue.file;
        }

        if (issue.line) {
          parsedIssue.urlPath = parsedSecurityUrl += `#L${issue.line}`;
        }
      }

      return parsedIssue;
    });
  }

  static filterByFingerprint(firstArray, secondArray) {
    return firstArray.filter(item => !secondArray.find(el => el.fingerprint === item.fingerprint));
  }
}

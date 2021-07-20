import getStateKey from 'ee_else_ce/vue_merge_request_widget/stores/get_state_key';
import { statusBoxState } from '~/issuable/components/status_box.vue';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import { MTWPS_MERGE_STRATEGY, MT_MERGE_STRATEGY, MWPS_MERGE_STRATEGY } from '../constants';
import { stateKey } from './state_maps';

const { format } = getTimeago();

export default class MergeRequestStore {
  constructor(data) {
    this.sha = data.diff_head_sha;
    this.gitlabLogo = data.gitlabLogo;

    this.apiApprovalsPath = data.api_approvals_path;
    this.apiApprovePath = data.api_approve_path;
    this.apiUnapprovePath = data.api_unapprove_path;
    this.hasApprovalsAvailable = data.has_approvals_available;

    this.setPaths(data);

    this.setData(data);
  }

  setData(data, isRebased) {
    this.initApprovals();

    this.updateStatusState(data.state);

    if (isRebased) {
      this.sha = data.diff_head_sha;
    }

    const pipelineStatus = data.pipeline ? data.pipeline.details.status : null;

    this.squash = data.squash;
    this.squashIsEnabledByDefault = data.squash_enabled_by_default;
    this.squashIsReadonly = data.squash_readonly;
    this.enableSquashBeforeMerge = this.enableSquashBeforeMerge || true;
    this.squashIsSelected = data.squash_readonly ? data.squash_on_merge : data.squash;

    this.iid = data.iid;
    this.title = data.title;
    this.targetBranch = data.target_branch;
    this.targetBranchSha = data.target_branch_sha;
    this.sourceBranch = data.source_branch;
    this.sourceBranchProtected = data.source_branch_protected;
    this.conflictsDocsPath = data.conflicts_docs_path;
    this.mergeTrainWhenPipelineSucceedsDocsPath = data.merge_train_when_pipeline_succeeds_docs_path;
    this.commitMessage = data.default_merge_commit_message;
    this.shortMergeCommitSha = data.short_merged_commit_sha;
    this.mergeCommitSha = data.merged_commit_sha;
    this.commitMessageWithDescription = data.default_merge_commit_message_with_description;
    this.divergedCommitsCount = data.diverged_commits_count;
    this.pipeline = data.pipeline || {};
    this.pipelineCoverageDelta = data.pipeline_coverage_delta;
    this.buildsWithCoverage = data.builds_with_coverage;
    this.mergePipeline = data.merge_pipeline || {};
    this.deployments = this.deployments || data.deployments || [];
    this.postMergeDeployments = this.postMergeDeployments || [];
    this.commits = data.commits_without_merge_commits || [];
    this.squashCommitMessage = data.default_squash_commit_message;
    this.rebaseInProgress = data.rebase_in_progress;
    this.mergeRequestDiffsPath = data.diffs_path;
    this.approvalsWidgetType = data.approvals_widget_type;
    this.mergeRequestWidgetPath = data.merge_request_widget_path;

    if (data.issues_links) {
      const links = data.issues_links;
      const { closing } = links;
      const mentioned = links.mentioned_but_not_closing;
      const assignToMe = links.assign_to_closing;

      if (closing || mentioned || assignToMe) {
        this.relatedLinks = { closing, mentioned, assignToMe };
      }
    }

    this.updatedAt = data.updated_at;
    this.metrics = MergeRequestStore.buildMetrics(data.metrics);
    this.setToAutoMergeBy = MergeRequestStore.formatUserObject(data.merge_user || {});
    this.mergeUserId = data.merge_user_id;
    this.currentUserId = gon.current_user_id;
    this.sourceBranchRemoved = !data.source_branch_exists;
    this.shouldRemoveSourceBranch = data.remove_source_branch || false;
    this.autoMergeStrategy = data.auto_merge_strategy;
    this.availableAutoMergeStrategies = data.available_auto_merge_strategies;
    this.preferredAutoMergeStrategy = MergeRequestStore.getPreferredAutoMergeStrategy(
      this.availableAutoMergeStrategies,
    );
    this.ffOnlyEnabled = data.ff_only_enabled;
    this.isRemovingSourceBranch = this.isRemovingSourceBranch || false;
    this.mergeRequestState = data.state;
    this.isOpen = this.mergeRequestState === 'opened';
    this.latestSHA = data.diff_head_sha;
    this.isMergeAllowed = data.mergeable || false;
    this.mergeOngoing = data.merge_ongoing;
    this.allowCollaboration = data.allow_collaboration;
    this.sourceProjectId = data.source_project_id;
    this.targetProjectId = data.target_project_id;

    // CI related
    this.hasCI = data.has_ci;
    this.ciStatus = data.ci_status;
    this.isPipelinePassing =
      this.ciStatus === 'success' || this.ciStatus === 'success-with-warnings';
    this.isPipelineSkipped = this.ciStatus === 'skipped';
    this.pipelineDetailedStatus = pipelineStatus;
    this.isPipelineActive = data.pipeline ? data.pipeline.active : false;
    this.isPipelineBlocked =
      data.only_allow_merge_if_pipeline_succeeds && pipelineStatus?.group === 'manual';
    this.ciStatusFaviconPath = pipelineStatus ? pipelineStatus.favicon : null;
    this.terraformReportsPath = data.terraform_reports_path;
    this.testResultsPath = data.test_reports_path;
    this.accessibilityReportPath = data.accessibility_report_path;
    this.exposedArtifactsPath = data.exposed_artifacts_path;
    this.cancelAutoMergePath = data.cancel_auto_merge_path;
    this.canCancelAutomaticMerge = Boolean(data.cancel_auto_merge_path);

    this.newBlobPath = data.new_blob_path;
    this.sourceBranchPath = data.source_branch_path;
    this.sourceBranchLink = data.source_branch_with_namespace_link;
    this.rebasePath = data.rebase_path;
    this.targetBranchPath = data.target_branch_commits_path;
    this.targetBranchTreePath = data.target_branch_tree_path;
    this.conflictResolutionPath = data.conflict_resolution_path;
    this.removeWIPPath = data.remove_wip_path;
    this.createIssueToResolveDiscussionsPath = data.create_issue_to_resolve_discussions_path;
    this.mergePath = data.merge_path;
    this.mergeCommitPath = data.merged_commit_path;
    this.canPushToSourceBranch = data.can_push_to_source_branch;

    if (!window.gon?.features?.mergeRequestWidgetGraphql) {
      this.autoMergeEnabled = Boolean(data.auto_merge_enabled);
      this.canBeMerged = data.can_be_merged || false;
      this.canMerge = Boolean(data.merge_path);
      this.commitsCount = data.commits_count;
      this.branchMissing = data.branch_missing;
      this.hasConflicts = data.has_conflicts;
      this.hasMergeableDiscussionsState = data.mergeable_discussions_state === false;
      this.isPipelineFailed = this.ciStatus === 'failed' || this.ciStatus === 'canceled';
      this.mergeError = data.merge_error;
      this.mergeStatus = data.merge_status;
      this.onlyAllowMergeIfPipelineSucceeds = data.only_allow_merge_if_pipeline_succeeds || false;
      this.projectArchived = data.project_archived;
      this.isSHAMismatch = this.sha !== data.diff_head_sha;
      this.shouldBeRebased = Boolean(data.should_be_rebased);
      this.workInProgress = data.work_in_progress;
    }

    const currentUser = data.current_user;

    this.cherryPickInForkPath = currentUser.cherry_pick_in_fork_path;
    this.revertInForkPath = currentUser.revert_in_fork_path;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canCreateIssue = currentUser.can_create_issue || false;
    this.canCherryPickInCurrentMR = currentUser.can_cherry_pick_on_current_merge_request || false;
    this.canRevertInCurrentMR = currentUser.can_revert_on_current_merge_request || false;

    this.setState();
  }

  setGraphqlData(project) {
    const { mergeRequest } = project;
    const pipeline = mergeRequest.headPipeline;

    this.updateStatusState(mergeRequest.state);

    this.projectArchived = project.archived;
    this.onlyAllowMergeIfPipelineSucceeds = project.onlyAllowMergeIfPipelineSucceeds;

    this.autoMergeEnabled = mergeRequest.autoMergeEnabled;
    this.canBeMerged = mergeRequest.mergeStatus === 'can_be_merged';
    this.canMerge = mergeRequest.userPermissions.canMerge;
    this.ciStatus = pipeline?.status.toLowerCase();

    if (pipeline?.warnings && this.ciStatus === 'success') {
      this.ciStatus = `${this.ciStatus}-with-warnings`;
    }

    this.commitsCount = mergeRequest.commitCount;
    this.branchMissing = !mergeRequest.sourceBranchExists || !mergeRequest.targetBranchExists;
    this.hasConflicts = mergeRequest.conflicts;
    this.hasMergeableDiscussionsState = mergeRequest.mergeableDiscussionsState === false;
    this.mergeError = mergeRequest.mergeError;
    this.mergeStatus = mergeRequest.mergeStatus;
    this.isPipelineFailed = this.ciStatus === 'failed' || this.ciStatus === 'canceled';
    this.isSHAMismatch = this.sha !== mergeRequest.diffHeadSha;
    this.shouldBeRebased = mergeRequest.shouldBeRebased;
    this.workInProgress = mergeRequest.workInProgress;
    this.mergeRequestState = mergeRequest.state;

    this.setState();
  }

  updateStatusState(state) {
    if (this.mergeRequestState !== state && statusBoxState.updateStatus) {
      statusBoxState.updateStatus();
    }
  }

  setState() {
    if (this.mergeOngoing) {
      this.state = 'merging';
      return;
    }

    if (this.isOpen) {
      this.state = getStateKey.call(this);
    } else {
      switch (this.mergeRequestState) {
        case 'merged':
          this.state = 'merged';
          break;
        case 'closed':
          this.state = 'closed';
          break;
        default:
          this.state = null;
      }
    }
  }

  setPaths(data) {
    // Paths are set on the first load of the page and not auto-refreshed
    this.squashBeforeMergeHelpPath = data.squash_before_merge_help_path;
    this.mrTroubleshootingDocsPath = data.mr_troubleshooting_docs_path;
    this.ciTroubleshootingDocsPath = data.ci_troubleshooting_docs_path;
    this.pipelineMustSucceedDocsPath = data.pipeline_must_succeed_docs_path;
    this.mergeRequestBasicPath = data.merge_request_basic_path;
    this.mergeRequestWidgetPath = data.merge_request_widget_path;
    this.mergeRequestCachedWidgetPath = data.merge_request_cached_widget_path;
    this.emailPatchesPath = data.email_patches_path;
    this.plainDiffPath = data.plain_diff_path;
    this.mergeCheckPath = data.merge_check_path;
    this.mergeActionsContentPath = data.commit_change_content_path;
    this.targetProjectFullPath = data.target_project_full_path;
    this.sourceProjectFullPath = data.source_project_full_path;
    this.mergeRequestPipelinesHelpPath = data.merge_request_pipelines_docs_path;
    this.conflictsDocsPath = data.conflicts_docs_path;
    this.reviewingDocsPath = data.reviewing_and_managing_merge_requests_docs_path;
    this.ciEnvironmentsStatusPath = data.ci_environments_status_path;
    this.securityApprovalsHelpPagePath = data.security_approvals_help_page_path;
    this.licenseComplianceDocsPath = data.license_compliance_docs_path;
    this.eligibleApproversDocsPath = data.eligible_approvers_docs_path;
    this.mergeImmediatelyDocsPath = data.merge_immediately_docs_path;
    this.approvalsHelpPath = data.approvals_help_path;
    this.mergeRequestAddCiConfigPath = data.merge_request_add_ci_config_path;
    this.pipelinesEmptySvgPath = data.pipelines_empty_svg_path;
    this.humanAccess = data.human_access;
    this.newPipelinePath = data.new_project_pipeline_path;
    this.sourceProjectDefaultUrl = data.source_project_default_url;
    this.userCalloutsPath = data.user_callouts_path;
    this.suggestPipelineFeatureId = data.suggest_pipeline_feature_id;
    this.isDismissedSuggestPipeline = data.is_dismissed_suggest_pipeline;
    this.securityReportsDocsPath = data.security_reports_docs_path;

    // code quality
    const blobPath = data.blob_path || {};
    this.headBlobPath = blobPath.head_path || '';
    this.baseBlobPath = blobPath.base_path || '';
    this.codequalityReportsPath = data.codequality_reports_path;
    this.codequalityHelpPath = data.codequality_help_path;
    this.codeclimate = data.codeclimate;

    // Security reports
    this.sastComparisonPath = data.sast_comparison_path;
    this.secretScanningComparisonPath = data.secret_scanning_comparison_path;
  }

  get isNothingToMergeState() {
    return this.state === stateKey.nothingToMerge;
  }

  get isMergedState() {
    return this.state === stateKey.merged;
  }

  static buildMetrics(metrics) {
    if (!metrics) {
      return {};
    }

    return {
      mergedBy: MergeRequestStore.formatUserObject(metrics.merged_by),
      closedBy: MergeRequestStore.formatUserObject(metrics.closed_by),
      mergedAt: formatDate(metrics.merged_at),
      closedAt: formatDate(metrics.closed_at),
      readableMergedAt: MergeRequestStore.getReadableDate(metrics.merged_at),
      readableClosedAt: MergeRequestStore.getReadableDate(metrics.closed_at),
    };
  }

  static formatUserObject(user) {
    if (!user) {
      return {};
    }

    return {
      name: user.name || '',
      username: user.username || '',
      webUrl: user.web_url || '',
      avatarUrl: user.avatar_url || '',
    };
  }

  static getReadableDate(date) {
    if (!date) {
      return '';
    }

    return format(date);
  }

  static getPreferredAutoMergeStrategy(availableAutoMergeStrategies) {
    if (availableAutoMergeStrategies === undefined) return undefined;

    if (availableAutoMergeStrategies.includes(MTWPS_MERGE_STRATEGY)) {
      return MTWPS_MERGE_STRATEGY;
    } else if (availableAutoMergeStrategies.includes(MT_MERGE_STRATEGY)) {
      return MT_MERGE_STRATEGY;
    } else if (availableAutoMergeStrategies.includes(MWPS_MERGE_STRATEGY)) {
      return MWPS_MERGE_STRATEGY;
    }

    return undefined;
  }

  initApprovals() {
    this.isApproved = this.isApproved || false;
    this.approvals = this.approvals || null;
  }

  setApprovals(data) {
    this.approvals = data;
    this.isApproved = data.approved || false;
  }
}

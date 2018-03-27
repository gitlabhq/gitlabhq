import Timeago from 'timeago.js';
import { getStateKey } from '../dependencies';
import { stateKey } from './state_maps';
import { formatDate } from '../../lib/utils/datetime_utility';

export default class MergeRequestStore {
  constructor(data) {
    this.sha = data.diff_head_sha;
    this.gitlabLogo = data.gitlabLogo;

    this.setData(data);
  }

  setData(data) {
    const currentUser = data.current_user;
    const pipelineStatus = data.pipeline ? data.pipeline.details.status : null;

    this.title = data.title;
    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;
    this.mergeStatus = data.merge_status;
    this.commitMessage = data.merge_commit_message;
    this.commitMessageWithDescription = data.merge_commit_message_with_description;
    this.commitsCount = data.commits_count;
    this.divergedCommitsCount = data.diverged_commits_count;
    this.pipeline = data.pipeline || {};
    this.deployments = this.deployments || data.deployments || [];
    this.initRebase(data);

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
    this.setToMWPSBy = MergeRequestStore.formatUserObject(data.merge_user || {});
    this.mergeUserId = data.merge_user_id;
    this.currentUserId = gon.current_user_id;
    this.sourceBranchPath = data.source_branch_path;
    this.sourceBranchLink = data.source_branch_with_namespace_link;
    this.mergeError = data.merge_error;
    this.targetBranchPath = data.target_branch_commits_path;
    this.targetBranchTreePath = data.target_branch_tree_path;
    this.conflictResolutionPath = data.conflict_resolution_path;
    this.cancelAutoMergePath = data.cancel_merge_when_pipeline_succeeds_path;
    this.removeWIPPath = data.remove_wip_path;
    this.sourceBranchRemoved = !data.source_branch_exists;
    this.shouldRemoveSourceBranch = data.remove_source_branch || false;
    this.onlyAllowMergeIfPipelineSucceeds = data.only_allow_merge_if_pipeline_succeeds || false;
    this.mergeWhenPipelineSucceeds = data.merge_when_pipeline_succeeds || false;
    this.mergePath = data.merge_path;
    this.ffOnlyEnabled = data.ff_only_enabled;
    this.shouldBeRebased = !!data.should_be_rebased;
    this.statusPath = data.status_path;
    this.emailPatchesPath = data.email_patches_path;
    this.plainDiffPath = data.plain_diff_path;
    this.newBlobPath = data.new_blob_path;
    this.createIssueToResolveDiscussionsPath = data.create_issue_to_resolve_discussions_path;
    this.mergeCheckPath = data.merge_check_path;
    this.mergeActionsContentPath = data.commit_change_content_path;
    this.isRemovingSourceBranch = this.isRemovingSourceBranch || false;
    this.isOpen = data.state === 'opened';
    this.hasMergeableDiscussionsState = data.mergeable_discussions_state === false;
    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canMerge = !!data.merge_path;
    this.canCreateIssue = currentUser.can_create_issue || false;
    this.canCancelAutomaticMerge = !!data.cancel_merge_when_pipeline_succeeds_path;
    this.hasSHAChanged = this.sha !== data.diff_head_sha;
    this.canBeMerged = data.can_be_merged || false;
    this.isMergeAllowed = data.mergeable || false;
    this.mergeOngoing = data.merge_ongoing;
    this.maintainerEditAllowed = data.allow_maintainer_to_push;

    // Cherry-pick and Revert actions related
    this.canCherryPickInCurrentMR = currentUser.can_cherry_pick_on_current_merge_request || false;
    this.canRevertInCurrentMR = currentUser.can_revert_on_current_merge_request || false;
    this.cherryPickInForkPath = currentUser.cherry_pick_in_fork_path;
    this.revertInForkPath = currentUser.revert_in_fork_path;

    // CI related
    this.ciEnvironmentsStatusPath = data.ci_environments_status_path;
    this.hasCI = data.has_ci;
    this.ciStatus = data.ci_status;
    this.isPipelineFailed = this.ciStatus === 'failed' || this.ciStatus === 'canceled';
    this.isPipelinePassing = this.ciStatus === 'success' || this.ciStatus === 'success_with_warnings';
    this.isPipelineSkipped = this.ciStatus === 'skipped';
    this.pipelineDetailedStatus = pipelineStatus;
    this.isPipelineActive = data.pipeline ? data.pipeline.active : false;
    this.isPipelineBlocked = pipelineStatus ? pipelineStatus.group === 'manual' : false;
    this.ciStatusFaviconPath = pipelineStatus ? pipelineStatus.favicon : null;

    this.setState(data);
  }

  setState(data) {
    if (this.mergeOngoing) {
      this.state = 'merging';
      return;
    }

    if (this.isOpen) {
      this.state = getStateKey.call(this, data);
    } else {
      switch (data.state) {
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

  get isNothingToMergeState() {
    return this.state === stateKey.nothingToMerge;
  }

  get isMergedState() {
    return this.state === stateKey.merged;
  }

  initRebase(data) {
    this.canPushToSourceBranch = data.can_push_to_source_branch;
    this.rebaseInProgress = data.rebase_in_progress;
    this.approvalsLeft = !data.approved;
    this.rebasePath = data.rebase_path;
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

    const timeagoInstance = new Timeago();

    return timeagoInstance.format(date);
  }
}

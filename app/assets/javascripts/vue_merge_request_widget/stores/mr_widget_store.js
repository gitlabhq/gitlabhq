import Timeago from 'timeago.js';
import { getStateKey } from '../dependencies';

export default class MergeRequestStore {
  constructor(data) {
    this.sha = data.diff_head_sha;
    this.gitlabLogo = data.gitlabLogo;

    this.setData(data);
  }

  setData(data) {
    const currentUser = data.current_user;
    const pipelineStatus = data.pipeline ? data.pipeline.details.status : null;

    // EE specific
    this.squash = data.squash;

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
    this.mergedAt = MergeRequestStore.getEventDate(data.merge_event);
    this.closedAt = MergeRequestStore.getEventDate(data.closed_event);
    this.mergedBy = MergeRequestStore.getAuthorObject(data.merge_event);
    this.closedBy = MergeRequestStore.getAuthorObject(data.closed_event);
    this.setToMWPSBy = MergeRequestStore.getAuthorObject({ author: data.merge_user || {} });
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
    this.statusPath = data.status_path;
    this.emailPatchesPath = data.email_patches_path;
    this.plainDiffPath = data.plain_diff_path;
    this.newBlobPath = data.new_blob_path;
    this.createIssueToResolveDiscussionsPath = data.create_issue_to_resolve_discussions_path;
    this.mergeCheckPath = data.merge_check_path;
    this.mergeActionsContentPath = data.commit_change_content_path;
    this.isRemovingSourceBranch = this.isRemovingSourceBranch || false;
    this.isOpen = data.state === 'opened' || data.state === 'reopened' || false;
    this.hasMergeableDiscussionsState = data.mergeable_discussions_state === false;
    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canMerge = !!data.merge_path;
    this.canCreateIssue = currentUser.can_create_issue || false;
    this.canCancelAutomaticMerge = !!data.cancel_merge_when_pipeline_succeeds_path;
    this.hasSHAChanged = this.sha !== data.diff_head_sha;
    this.canBeMerged = data.can_be_merged || false;

    // Cherry-pick and Revert actions related
    this.canCherryPickInCurrentMR = currentUser.can_cherry_pick_on_current_merge_request || false;
    this.canRevertInCurrentMR = currentUser.can_revert_on_current_merge_request || false;
    this.cherryPickInForkPath = currentUser.cherry_pick_in_fork_path;
    this.revertInForkPath = currentUser.revert_in_fork_path;

    // CI related
    this.ciEnvironmentsStatusPath = data.ci_environments_status_path;
    this.hasCI = data.has_ci;
    this.ciStatus = data.ci_status;
    this.isPipelineFailed = this.ciStatus ? (this.ciStatus === 'failed' || this.ciStatus === 'canceled') : false;
    this.pipelineDetailedStatus = pipelineStatus;
    this.isPipelineActive = data.pipeline ? data.pipeline.active : false;
    this.isPipelineBlocked = pipelineStatus ? pipelineStatus.group === 'manual' : false;
    this.ciStatusFaviconPath = pipelineStatus ? pipelineStatus.favicon : null;

    this.setState(data);
  }

  setState(data) {
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
        case 'locked':
          this.state = 'locked';
          break;
        default:
          this.state = null;
      }
    }
  }

  static getAuthorObject(event) {
    if (!event) {
      return {};
    }

    return {
      name: event.author.name || '',
      username: event.author.username || '',
      webUrl: event.author.web_url || '',
      avatarUrl: event.author.avatar_url || '',
    };
  }

  static getEventDate(event) {
    const timeagoInstance = new Timeago();

    if (!event) {
      return '';
    }

    return timeagoInstance.format(event.updated_at);
  }
}

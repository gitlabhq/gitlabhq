import Timeago from 'timeago.js';

export default class MergeRequestStore {

  constructor(data) {
    this.setData(data);
  }

  setData(data) {
    // TODO: Remove this
    this.rawData = data || {};

    const currentUser = data.current_user;

    this.title = data.title;
    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;
    this.mergeStatus = data.merge_status;
    this.sha = data.diff_head_sha;
    this.commitMessage = data.merge_commit_message;
    this.commitMessageWithDescription = data.merge_commit_message_with_description;
    this.divergedCommitsCount = data.diverged_commits_count;
    this.pipeline = data.pipeline;
    this.deployments = data.deployments || [];

    if (data.issues_links) {
      const { closing, mentioned_but_not_closing } = data.issues_links;
      this.relatedLinks = {
        closing,
        mentioned: mentioned_but_not_closing,
      };
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
    this.targetBranchPath = data.target_branch_path;
    this.conflictResolutionPath = data.conflict_resolution_ui_path;
    this.cancelAutoMergePath = data.cancel_merge_when_pipeline_succeeds_path;
    this.removeWIPPath = data.remove_wip_path;
    this.sourceBranchRemoved = !data.source_branch_exists;
    this.shouldRemoveSourceBranch = (data.merge_params || {}).should_remove_source_branch || false;
    this.onlyAllowMergeIfPipelineSucceeds = data.only_allow_merge_if_pipeline_succeeds || false;
    this.mergeWhenPipelineSucceeds = data.merge_when_pipeline_succeeds || false;
    this.mergePath = data.merge_path;
    this.statusPath = data.status_path;
    this.emailPatchesPath = data.email_patches_path;
    this.plainDiffPath = data.plain_diff_path;
    this.createIssueToResolveDiscussionsPath = data.create_issue_to_resolve_discussions_path;
    this.ciEnvironmentsStatusPath = data.ci_environments_status_url;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canRevert = currentUser.can_revert || false;
    this.canResolveConflicts = currentUser.can_resolve_conflicts || false;
    this.canMerge = currentUser.can_merge || false;
    this.canCreateIssue = currentUser.can_create_issue || false;
    this.canCancelAutomaticMerge = currentUser.can_cancel_automatic_merge || false;
    this.canUpdateMergeRequest = currentUser.can_update_merge_request || false;
    this.canResolveConflictsInUI = data.conflicts_can_be_resolved_in_ui || false;
    this.canBeCherryPicked = data.can_be_cherry_picked || false;
    this.canBeMerged = data.can_be_merged || false;

    this.isPipelineActive = data.pipeline ? data.pipeline.active : false;
    this.isPipelineFailed = data.pipeline ? data.pipeline.details.status.group === 'failed' : false;
    this.isPipelineBlocked = data.pipeline ? data.pipeline.details.status.group === 'manual' : false;
    this.isOpen = data.state === 'opened' || data.state === 'reopened' || false;

    this.setState(data);
  }

  setState(data) {
    if (this.isOpen) {
      if (data.project_archived) {
        this.state = 'archived';
      } else if (data.branch_missing) {
        this.state = 'missingBranch';
      } else if (data.has_no_commits) {
        this.state = 'nothingToMerge';
      } else if (this.mergeStatus === 'unchecked') {
        this.state = 'checking';
      } else if (data.has_conflicts) {
        this.state = 'conflicts';
      } else if (data.work_in_progress) {
        this.state = 'workInProgress';
      } else if (this.mergeWhenPipelineSucceeds) {
        this.state = 'mergeWhenPipelineSucceeds';
      } else if (!this.canMerge) {
        this.state = 'notAllowedToMerge';
      } else if (this.onlyAllowMergeIfPipelineSucceeds && this.isPipelineFailed) {
        this.state = 'pipelineFailed';
      } else if (this.mergeable_discussions_state === false) {
        this.state = 'unresolvedDiscussions';
      } else if (this.isPipelineBlocked) {
        this.state = 'pipelineBlocked';
      } else if (this.canBeMerged) {
        this.state = 'readyToMerge';
      }
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

import Timeago from 'timeago.js';

export default class MergeRequestStore {

  constructor(data) {
    // TODO: Remove this
    this.rawData = data || {};

    const currentUser = data.current_user;

    this.state = data.state;
    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;

    this.updatedAt = data.updated_at;
    this.mergedAt = MergeRequestStore.getEventDate(data.merge_event);
    // FIXME: replace it with merge_event.author
    this.mergedBy = MergeRequestStore.getUserObject(data.author);

    // FIXME: replace it with close_event.author
    this.closedBy = MergeRequestStore.getUserObject(data.author);
    this.closedAt = MergeRequestStore.getEventDate(data.closed_event);

    this.targetBranchPath = data.target_branch_path;
    this.sourceBranchRemoved = !data.source_branch_exists;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canRevert = currentUser.can_revert || false;
    this.canBeCherryPicked = data.can_be_cherry_picked || false;

    this.isMerged = this.state === 'merged';
    this.isClosed = this.state === 'closed';
    this.isLocked = this.state === 'locked';
    this.isWip = this.state === 'opened' && data.work_in_progress && data.merge_status === 'can_be_merged';
    this.isArchived = data.project_archived;
  }

  static getUserObject(user) {
    return {
      name: user.name || '',
      username: user.username || '',
      webUrl: user.web_url || '',
      avatarUrl: user.avatar_url || '',
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

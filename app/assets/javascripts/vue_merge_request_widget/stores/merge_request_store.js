module.exports = class MergeRequestStore {

  constructor(data) {
    // TODO: Remove this
    this.rawData = data || {};

    this.state = data.state;
    this.targetBranch = data.target_branch;
    this.sourceBranch = data.source_branch;

    this.updatedAt = data.updated_at;
    this.mergedAt = this.getEventDate(data.merge_event);
    this.mergedBy = this.getUserObject(data.author); // FIXME: replace it with merge_event.author

    this.closedBy = this.getUserObject(data.author); // FIXME: replace it with close_event.author
    this.closedAt = this.getEventDate(data.closed_event);

    this.targetBranchPath = data.target_branch_path;
    this.sourceBranchRemoved = !data.source_branch_exists;

    const currentUser = data.current_user;

    this.canRemoveSourceBranch = currentUser.can_remove_source_branch || false;
    this.canRevert = currentUser.can_revert || false;
    this.canBeCherryPicked = data.can_be_cherry_picked || false;

    this.isMerged = this.state == 'merged';
    this.isClosed = this.state == 'closed';
    this.isLocked = this.state == 'locked';
    this.isWip = this.state == 'opened' && data.work_in_progress && data.merge_status == 'can_be_merged';
    this.isArchived = data.project_archived;
  }

  getUserObject(user) {
    return {
      name: user.name || '',
      username: user.username || '',
      webUrl: user.web_url || '',
      avatarUrl: user.avatar_url || '',
    }
  }

  getEventDate(event) {
    if (!event) {
      return '';
    }

    return gl.mrWidget.timeagoInstance.format(event.updated_at);
  }

}

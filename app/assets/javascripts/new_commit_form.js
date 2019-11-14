/* eslint-disable no-return-assign */
export default class NewCommitForm {
  constructor(form) {
    this.form = form;
    this.renderDestination = this.renderDestination.bind(this);
    this.branchName = form.find('.js-branch-name');
    this.originalBranch = form.find('.js-original-branch');
    this.createMergeRequest = form.find('.js-create-merge-request');
    this.createMergeRequestContainer = form.find('.js-create-merge-request-container');
    this.branchName.keyup(this.renderDestination);
    this.renderDestination();
  }
  renderDestination() {
    const different = this.branchName.val() !== this.originalBranch.val();
    if (different) {
      this.createMergeRequestContainer.show();
      if (!this.wasDifferent) {
        this.createMergeRequest.prop('checked', true);
      }
    } else {
      this.createMergeRequestContainer.hide();
      this.createMergeRequest.prop('checked', false);
    }
    return (this.wasDifferent = different);
  }
}

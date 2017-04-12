/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, max-len */

import '~/lib/utils/url_utility';

(function() {
  this.MergedButtons = (function() {
    function MergedButtons() {
      this.removeSourceBranch = this.removeSourceBranch.bind(this);
      this.removeBranchSuccess = this.removeBranchSuccess.bind(this);
      this.removeBranchError = this.removeBranchError.bind(this);
      this.$removeBranchWidget = $('.remove_source_branch_widget');
      this.$removeBranchProgress = $('.remove_source_branch_in_progress');
      this.$removeBranchFailed = $('.remove_source_branch_widget.failed');
      this.cleanEventListeners();
      this.initEventListeners();
    }

    MergedButtons.prototype.cleanEventListeners = function() {
      $(document).off('click', '.remove_source_branch');
      $(document).off('ajax:success', '.remove_source_branch');
      return $(document).off('ajax:error', '.remove_source_branch');
    };

    MergedButtons.prototype.initEventListeners = function() {
      $(document).on('click', '.remove_source_branch', this.removeSourceBranch);
      $(document).on('ajax:success', '.remove_source_branch', this.removeBranchSuccess);
      $(document).on('ajax:error', '.remove_source_branch', this.removeBranchError);
    };

    MergedButtons.prototype.removeSourceBranch = function() {
      this.$removeBranchWidget.hide();
      return this.$removeBranchProgress.show();
    };

    MergedButtons.prototype.removeBranchSuccess = function() {
      gl.utils.refreshCurrentPage();
    };

    MergedButtons.prototype.removeBranchError = function() {
      this.$removeBranchWidget.hide();
      this.$removeBranchProgress.hide();
      return this.$removeBranchFailed.show();
    };

    return MergedButtons;
  })();
}).call(window);

/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, no-undef, padded-blocks, max-len */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.MergedButtons = (function() {
    function MergedButtons() {
      this.removeSourceBranch = bind(this.removeSourceBranch, this);
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
      return $(document).on('ajax:error', '.remove_source_branch', this.removeBranchError);
    };

    MergedButtons.prototype.removeSourceBranch = function() {
      this.$removeBranchWidget.hide();
      return this.$removeBranchProgress.show();
    };

    MergedButtons.prototype.removeBranchSuccess = function() {
      return location.reload();
    };

    MergedButtons.prototype.removeBranchError = function() {
      this.$removeBranchWidget.hide();
      this.$removeBranchProgress.hide();
      return this.$removeBranchFailed.show();
    };

    return MergedButtons;

  })();

}).call(this);

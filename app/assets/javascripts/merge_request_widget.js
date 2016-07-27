(function() {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  this.MergeRequestWidget = (function() {
    function MergeRequestWidget(opts) {
      // Initialize MergeRequestWidget behavior
      //
      //   check_enable           - Boolean, whether to check automerge status
      //   merge_check_url - String, URL to use to check automerge status
      //   ci_status_url        - String, URL to use to check CI status
      //
      this.mergeRequestWidget = $('.mr-state-widget');
      this.mergeRequestWidgetBody = $('.mr-widget-body');
      this.opts = opts || $('.js-merge-request-widget-options').data();
      this.getInputs();
      this.getButtons(true);
      if (this.opts.checkStatus) {
        this.getMergeStatus();
      }

      $('#modal_merge_info').modal({
        show: false
      });
      this.firstCICheck = true;
      this.readyForCICheck = false;
      this.cancel = false;
      clearInterval(this.fetchBuildStatusInterval);
      this.clearButtonEventListeners();
      this.clearEventListeners();
      this.addButtonEventListeners();
      this.addEventListeners();
      this.getCIStatus(false);
      this.pollCIStatus();
      notifyPermissions();
    }

    MergeRequestWidget.prototype.getInputs = function() {
      this.acceptMergeRequestInput = $('.accept-mr-form :input');
      this.commitMessageInput = $('textarea[name=commit_message]');
      this.mergeWhenSucceedsInput = $('input[name=merge_when_build_succeeds]');
      this.removeSourceBranchInput = $('input[name=should_remove_source_branch]');
      this.shaInput = $('input[name=sha]');
      this.utfInput = $('input[name=utf8]');
      return this.authenticityTokenInput = $('input[name=authenticity_token]', this.mergeRequestWidget);
    };

    MergeRequestWidget.prototype.getButtons = function(skipListeners) {
      this.dynamicMergeButton = $('.js-merge-button');
      this.acceptMergeRequestButton = $('.accept_merge_request');
      this.cancelMergeOnSuccessButton = $('.js-cancel-automatic-merge');
      this.mergeWhenSucceedsButton = $('.merge_when_build_succeeds');
      this.removeSourceBranchButton = $('.remove_source_branch');
      this.removeSourceBranchWhenMergedButton = $('.remove_source_branch_when_merged');
      if (!skipListeners) {
        return this.addButtonEventListeners();
      }
    };

    MergeRequestWidget.prototype.clearEventListeners = function() {
      return $(document).off('page:change.merge_request');
    };

    MergeRequestWidget.prototype.clearButtonEventListeners = function() {
      this.mergeWhenSucceedsButton.off('click');
      this.acceptMergeRequestButton.off('click');
      this.cancelMergeOnSuccessButton.off('click');
      this.removeSourceBranchButton.off('click');
      return this.removeSourceBranchWhenMergedButton.off('click');
    };

    MergeRequestWidget.prototype.cancelPolling = function() {
      return this.cancel = true;
    };

    MergeRequestWidget.prototype.addEventListeners = function() {
      var allowedPages;
      allowedPages = ['show', 'commits', 'builds', 'pipelines', 'changes'];
      return $(document).on('page:change.merge_request', (function(_this) {
        return function() {
          var page;
          page = $('body').data('page').split(':').last();
          if (allowedPages.indexOf(page) < 0) {
            clearInterval(_this.fetchBuildStatusInterval);
            _this.cancelPolling();
            return _this.clearEventListeners();
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.addButtonEventListeners = function() {
      this.mergeWhenSucceedsButton.on('click', (function(_this) {
        return function(e) {
          _this.mergeWhenSucceedsInput.val('1');
          return _this.acceptMergeRequest(e);
        };
      })(this));
      this.removeSourceBranchWhenMergedButton.on('click', (function(_this) {
        return function(e) {
          _this.mergeWhenSucceedsInput.val('1');
          return _this.acceptMergeRequest(e, _this.removeSourceBranchWhenMergedButton.data('url'));
        };
      })(this));
      this.acceptMergeRequestButton.on('click', (function(_this) {
        return function(e) {
          return _this.acceptMergeRequest(e);
        };
      })(this));
      this.cancelMergeOnSuccessButton.on('click', (function(_this) {
        return function(e) {
          return _this.cancelMergeOnSuccess(e);
        };
      })(this));
      return this.removeSourceBranchButton.on('click', (function(_this) {
        return function(e) {
          return _this.removeSourceBranch(e);
        };
      })(this));
    };

    MergeRequestWidget.prototype.mergeInProgress = function(deleteSourceBranch) {
      if (deleteSourceBranch == null) {
        deleteSourceBranch = false;
      }
      return $.ajax({
        type: 'GET',
        url: $('.merge-request').data('url'),
        dataType: 'json',
        success: (function(_this) {
          return function(data) {
            var urlSuffix;
            if (data.state === "merged") {
              urlSuffix = deleteSourceBranch ? '?deleted_source_branch=true' : '';
              return window.location.href = window.location.pathname + urlSuffix;
            } else if (data.merge_error) {
              return _this.mergeRequestWidgetBody.html("<h4>" + data.merge_error + "</h4>");
            } else {
              return setTimeout(function() {
                return _this.mergeInProgress(deleteSourceBranch);
              }, 2000);
            }
          };
        })(this)
      });
    };

    MergeRequestWidget.prototype.getMergeStatus = function() {
      return $.get(this.opts.mergeCheckUrl, (function(_this) {
        return function(data) {
          _this.mergeRequestWidget.replaceWith(data);
          _this.getButtons();
          return _this.getInputs();
        };
      })(this));
    };

    MergeRequestWidget.prototype.ciLabelForStatus = function(status) {
      switch (status) {
        case 'success':
          return 'passed';
        case 'success_with_warnings':
          return 'passed with warnings';
        default:
          return status;
      }
    };

    MergeRequestWidget.prototype.pollCIStatus = function() {
      return this.fetchBuildStatusInterval = setInterval(((function(_this) {
        return function() {
          if (!_this.readyForCICheck) {
            return;
          }
          _this.getCIStatus(true);
          return _this.readyForCICheck = false;
        };
      })(this)), 10000);
    };

    MergeRequestWidget.prototype.getCIStatus = function(showNotification) {
      var _this;
      _this = this;
      $('.ci-widget-fetching').show();
      return $.getJSON(this.opts.ciStatusUrl, (function(_this) {
        return function(data) {
          var message, status, title;
          if (_this.cancel) {
            return;
          }
          _this.readyForCICheck = true;
          if (data.status === '') {
            return;
          }
          if (_this.firstCICheck || data.status !== _this.opts.ciStatus && (data.status != null)) {
            _this.opts.ciStatus = data.status;
            _this.showCIStatus(data.status);
            if (data.coverage) {
              _this.showCICoverage(data.coverage);
            }
            // The first check should only update the UI, a notification
            // should only be displayed on status changes
            if (showNotification && !_this.firstCICheck) {
              status = _this.ciLabelForStatus(data.status);
              if (status === "preparing") {
                title = _this.opts.ciTitle.preparing;
                status = status.charAt(0).toUpperCase() + status.slice(1);
                message = _this.opts.ciMessage.preparing.replace('{{status}}', status);
              } else {
                title = _this.opts.ciTitle.normal;
                message = _this.opts.ciMessage.normal.replace('{{status}}', status);
              }
              title = title.replace('{{status}}', status);
              message = message.replace('{{sha}}', data.sha);
              message = message.replace('{{title}}', data.title);
              notify(title, message, _this.opts.gitlabIcon, function() {
                this.close();
                return Turbolinks.visit(_this.opts.buildsPath);
              });
            }
            return _this.firstCICheck = false;
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.showCIStatus = function(state) {
      var allowed_states;
      if (state == null) {
        return;
      }
      $('.ci_widget').hide();
      allowed_states = ["failed", "canceled", "running", "pending", "success", "success_with_warnings", "skipped", "not_found"];
      if (indexOf.call(allowed_states, state) >= 0) {
        $('.ci_widget.ci-' + state).show();
        switch (state) {
          case "failed":
          case "canceled":
          case "not_found":
            return this.setMergeButtonClass('btn-danger');
          case "running":
            return this.setMergeButtonClass('btn-warning');
          case "success":
          case "success_with_warnings":
            return this.setMergeButtonClass('btn-create');
        }
      } else {
        $('.ci_widget.ci-error').show();
        return this.setMergeButtonClass('btn-danger');
      }
    };

    MergeRequestWidget.prototype.showCICoverage = function(coverage) {
      var text;
      text = 'Coverage ' + coverage + '%';
      return $('.ci_widget:visible .ci-coverage').text(text);
    };

    MergeRequestWidget.prototype.setMergeButtonClass = function(css_class) {
      return $('.js-merge-button,.accept-action .dropdown-toggle').removeClass('btn-danger btn-warning btn-create').addClass(css_class);
    };

    MergeRequestWidget.prototype.acceptMergeRequest = function(e, url) {
      if (e) {
        e.preventDefault();
      }
      this.acceptMergeRequestInput.disable();
      this.dynamicMergeButton.html('<i class="fa fa-spinner fa-spin"></i> Merge in progress');
      return $.ajax({
        method: 'POST',
        url: url || this.opts.mergePath,
        data: {
          utf8: this.utfInput.val(),
          authenticity_token: this.authenticityTokenInput.val(),
          sha: this.shaInput.val(),
          commit_message: this.commitMessageInput.val(),
          merge_when_build_succeeds: this.mergeWhenSucceedsInput.val(),
          should_remove_source_branch: this.removeSourceBranchInput.is(':checked') ? this.removeSourceBranchInput.val() : void 0
        }
      }).done((function(_this) {
        return function(res) {
          if (res.merge_in_progress != null) {
            return _this.mergeInProgress(res.merge_in_progress);
          } else {
            _this.mergeRequestWidgetBody.html(res);
            _this.getButtons();
            return _this.getInputs();
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.cancelMergeOnSuccess = function(e) {
      if (e) {
        e.preventDefault();
      }
      return $.ajax({
        method: 'POST',
        url: this.opts.cancelMergeOnSuccessPath
      }).done((function(_this) {
        return function(res) {
          _this.mergeRequestWidgetBody.html(res);
          _this.getButtons();
          return _this.getInputs();
        };
      })(this));
    };

    MergeRequestWidget.prototype.removeSourceBranch = function(e) {
      e.preventDefault();
      return $.ajax({
        method: 'DELETE',
        url: this.opts.removePath
      });
    };

    return MergeRequestWidget;

  })();

}).call(this);

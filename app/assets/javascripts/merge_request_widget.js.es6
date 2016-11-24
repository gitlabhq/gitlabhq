/* eslint-disable */
 ((global) => {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  const DEPLOYMENT_TEMPLATE = `<div class="mr-widget-heading" id="<%- id %>">
       <div class="ci_widget ci-success">
         <%= ci_success_icon %>
         <span>
           Deployed to
           <a href="<%- url %>" target="_blank" class="environment">
             <%- name %>
           </a>
           <span class="js-environment-timeago" data-toggle="tooltip" data-placement="top" data-title="<%- deployed_at_formatted %>">
             <%- deployed_at %>
           </span>
           <a class="js-environment-link" href="<%- external_url %>" target="_blank">
             <i class="fa fa-external-link"></i>
             View on <%- external_url_formatted %>
           </a>
         </span>
         <span class="stop-env-container js-stop-env-link">
          <a href="<%- stop_url %>" class="close-evn-link" data-method="post" rel="nofollow" data-confirm="Are you sure you want to stop this environment?">
            <i class="fa fa-stop-circle-o"/>
            Stop environment
          </a>
         </span>
       </div>
     </div>`;

   global.MergeRequestWidget = (function() {
    function MergeRequestWidget(opts) {
      // Initialize MergeRequestWidget behavior
      //
      //   check_enable           - Boolean, whether to check automerge status
      //   merge_check_url - String, URL to use to check automerge status
      //   ci_status_url        - String, URL to use to check CI status
      //
      this.opts = opts;
      this.$widgetBody = $('.mr-widget-body');
      $('#modal_merge_info').modal({
        show: false
      });
      this.firstCICheck = true;
      this.readyForCICheck = false;
      this.readyForCIEnvironmentCheck = false;
      this.cancel = false;
      clearInterval(this.fetchBuildStatusInterval);
      clearInterval(this.fetchBuildEnvironmentStatusInterval);
      this.clearEventListeners();
      this.addEventListeners();
      this.getCIStatus(false);
      this.getCIEnvironmentsStatus();
      this.retrieveSuccessIcon();
      this.pollCIStatus();
      this.pollCIEnvironmentsStatus();
      notifyPermissions();
    }

    MergeRequestWidget.prototype.clearEventListeners = function() {
      return $(document).off('page:change.merge_request');
    };

    MergeRequestWidget.prototype.cancelPolling = function() {
      return this.cancel = true;
    };

    MergeRequestWidget.prototype.addEventListeners = function() {
      var allowedPages;
      allowedPages = ['show', 'commits', 'builds', 'pipelines', 'changes'];
      $(document).on('page:change.merge_request', (function(_this) {
        return function() {
          var page;
          page = $('body').data('page').split(':').last();
          if (allowedPages.indexOf(page) < 0) {
            clearInterval(_this.fetchBuildStatusInterval);
            clearInterval(_this.fetchBuildEnvironmentStatusInterval);
            _this.cancelPolling();
            return _this.clearEventListeners();
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.retrieveSuccessIcon = function() {
       const $ciSuccessIcon = $('.js-success-icon');
       this.$ciSuccessIcon = $ciSuccessIcon.html();
       $ciSuccessIcon.remove();
     }

    MergeRequestWidget.prototype.mergeInProgress = function(deleteSourceBranch) {
      if (deleteSourceBranch == null) {
        deleteSourceBranch = false;
      }
      return $.ajax({
        type: 'GET',
        url: $('.merge-request').data('url'),
        success: (function(_this) {
          return function(data) {
            var callback, urlSuffix;
            if (data.state === "merged") {
              urlSuffix = deleteSourceBranch ? '?deleted_source_branch=true' : '';
              return window.location.href = window.location.pathname + urlSuffix;
            } else if (data.merge_error) {
              return this.$widgetBody.html("<h4>" + data.merge_error + "</h4>");
            } else {
              callback = function() {
                return merge_request_widget.mergeInProgress(deleteSourceBranch);
              };
              return setTimeout(callback, 2000);
            }
          };
        })(this),
        dataType: 'json'
      });
    };

    MergeRequestWidget.prototype.getMergeStatus = function() {
      return $.get(this.opts.merge_check_url, function(data) {
        return $('.mr-state-widget').replaceWith(data);
      });
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
      return $.getJSON(this.opts.ci_status_url, (function(_this) {
        return function(data) {
          var message, status, title;
          if (_this.cancel) {
            return;
          }
          _this.readyForCICheck = true;
          if (data.status === '') {
            return;
          }
          if (data.environments && data.environments.length) _this.renderEnvironments(data.environments);
          if (_this.firstCICheck || data.status !== _this.opts.ci_status && (data.status != null)) {
            _this.opts.ci_status = data.status;
            _this.showCIStatus(data.status);
            if (data.coverage) {
              _this.showCICoverage(data.coverage);
            }
            // The first check should only update the UI, a notification
            // should only be displayed on status changes
            if (showNotification && !_this.firstCICheck) {
              status = _this.ciLabelForStatus(data.status);
              if (status === "preparing") {
                title = _this.opts.ci_title.preparing;
                status = status.charAt(0).toUpperCase() + status.slice(1);
                message = _this.opts.ci_message.preparing.replace('{{status}}', status);
              } else {
                title = _this.opts.ci_title.normal;
                message = _this.opts.ci_message.normal.replace('{{status}}', status);
              }
              title = title.replace('{{status}}', status);
              message = message.replace('{{sha}}', data.sha);
              message = message.replace('{{title}}', data.title);
              notify(title, message, _this.opts.gitlab_icon, function() {
                this.close();
                return Turbolinks.visit(_this.opts.builds_path);
              });
            }
            return _this.firstCICheck = false;
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.pollCIEnvironmentsStatus = function() {
      this.fetchBuildEnvironmentStatusInterval = setInterval(() => {
        if (!this.readyForCIEnvironmentCheck) return;
        this.getCIEnvironmentsStatus();
        this.readyForCIEnvironmentCheck = false;
      }, 300000);
    };

    MergeRequestWidget.prototype.getCIEnvironmentsStatus = function() {
      $.getJSON(this.opts.ci_environments_status_url, (environments) => {
        if (this.cancel) return;
        this.readyForCIEnvironmentCheck = true;
        if (environments && environments.length) this.renderEnvironments(environments);
      });
    };

    MergeRequestWidget.prototype.renderEnvironments = function(environments) {
      for (let i = 0; i < environments.length; i++) {
        const environment = environments[i];
        if ($(`.mr-state-widget #${ environment.id }`).length) return;
        const $template = $(DEPLOYMENT_TEMPLATE);
        if (!environment.external_url || !environment.external_url_formatted) $('.js-environment-link', $template).remove();
        
        if (!environment.stop_url) {
          $('.js-stop-env-link', $template).remove();
        }
        
        if (environment.deployed_at && environment.deployed_at_formatted) {
          environment.deployed_at = gl.utils.getTimeago().format(environment.deployed_at, 'gl_en') + '.';
        } else {
          $('.js-environment-timeago', $template).remove();
          environment.name += '.';
        }
        environment.ci_success_icon = this.$ciSuccessIcon;
        const templateString = _.unescape($template[0].outerHTML);
        const template = _.template(templateString)(environment)
        this.$widgetBody.before(template);
      }
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
            return this.setMergeButtonClass('btn-info');
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
      return $('.js-merge-button,.accept-action .dropdown-toggle').removeClass('btn-danger btn-info btn-create').addClass(css_class);
    };

    return MergeRequestWidget;

  })();

 })(window.gl || (window.gl = {}));

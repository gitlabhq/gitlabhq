/* eslint-disable max-len, no-var, func-names, space-before-function-paren, vars-on-top, comma-dangle, no-return-assign, consistent-return, no-param-reassign, one-var, one-var-declaration-per-line, quotes, prefer-template, no-else-return, prefer-arrow-callback, no-unused-vars, no-underscore-dangle, no-shadow, no-mixed-operators, camelcase, default-case, wrap-iife */
/* global notify */
/* global notifyPermissions */
/* global merge_request_widget */

require('./smart_interval');

((global) => {
  var indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i += 1) { if (i in this && this[i] === item) return i; } return -1; };

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
      $('#modal_merge_info').modal({
        show: false
      });
      this.clearEventListeners();
      this.addEventListeners();
      this.getCIStatus(false);
      this.retrieveSuccessIcon();

      this.initMiniPipelineGraph();

      this.ciStatusInterval = new global.SmartInterval({
        callback: this.getCIStatus.bind(this, true),
        startingInterval: 10000,
        maxInterval: 30000,
        hiddenInterval: 120000,
        incrementByFactorOf: 5000,
      });
      this.ciEnvironmentStatusInterval = new global.SmartInterval({
        callback: this.getCIEnvironmentsStatus.bind(this),
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });

      notifyPermissions();
    }

    MergeRequestWidget.prototype.clearEventListeners = function() {
      return $(document).off('DOMContentLoaded');
    };

    MergeRequestWidget.prototype.addEventListeners = function() {
      var allowedPages;
      allowedPages = ['show', 'commits', 'pipelines', 'changes'];
      $(document).on('DOMContentLoaded', (function(_this) {
        return function() {
          var page;
          page = $('body').data('page').split(':').last();
          if (allowedPages.indexOf(page) < 0) {
            return _this.clearEventListeners();
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.retrieveSuccessIcon = function() {
      const $ciSuccessIcon = $('.js-success-icon');
      this.$ciSuccessIcon = $ciSuccessIcon.html();
      $ciSuccessIcon.remove();
    };

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
              return $('.mr-widget-body').html("<h4>" + data.merge_error + "</h4>");
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

    MergeRequestWidget.prototype.rebaseInProgress = function() {
      return $.ajax({
        type: 'GET',
        url: $('.merge-request').data('url'),
        success: (function(_this) {
          return function(data) {
            if (data["rebase_in_progress?"]) {
              return setTimeout(merge_request_widget.rebaseInProgress, 1000);
            } else {
              return location.reload();
            }
          };
        })(this),
        dataType: 'json'
      });
    };

    MergeRequestWidget.prototype.cancelPolling = function () {
      this.ciStatusInterval.cancel();
      this.ciEnvironmentStatusInterval.cancel();
    };

    MergeRequestWidget.prototype.getMergeStatus = function() {
      return $.get(this.opts.merge_check_url, function(data) {
        var $html = $(data);

        $('.mr-widget-body').replaceWith($html.find('.mr-widget-body'));
        $('.mr-widget-footer').replaceWith($html.find('.mr-widget-footer'));
        $('.approvals-components').replaceWith($html.find('.approvals-components'));

        if (gl.compileApprovalsWidget) {
          gl.compileApprovalsWidget();
        }
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

    MergeRequestWidget.prototype.getCIStatus = function(showNotification) {
      var _this;
      _this = this;
      $('.ci-widget-fetching').show();
      return $.getJSON(this.opts.ci_status_url, (function(_this) {
        return function(data) {
          var message, status, title;
          if (!data.status) {
            return;
          }
          if (data.environments && data.environments.length) _this.renderEnvironments(data.environments);
          if (data.status !== _this.opts.ci_status ||
              data.sha !== _this.opts.ci_sha ||
              data.pipeline !== _this.opts.ci_pipeline) {
            _this.opts.ci_status = data.status;
            _this.showCIStatus(data.status);
            if (data.coverage) {
              _this.showCICoverage(data.coverage);
            }
            if (data.pipeline) {
              _this.opts.ci_pipeline = data.pipeline;
              _this.updatePipelineUrls(data.pipeline);
            }
            if (data.sha) {
              _this.opts.ci_sha = data.sha;
              _this.updateCommitUrls(data.sha);
            }
            if (showNotification) {
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
              });
            }
          }
        };
      })(this));
    };

    MergeRequestWidget.prototype.getCIEnvironmentsStatus = function() {
      $.getJSON(this.opts.ci_environments_status_url, (environments) => {
        if (environments && environments.length) this.renderEnvironments(environments);
      });
    };

    MergeRequestWidget.prototype.renderEnvironments = function(environments) {
      for (let i = 0; i < environments.length; i += 1) {
        const environment = environments[i];
        if ($(`.mr-state-widget #${environment.id}`).length) return;
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
        const template = _.template(templateString)(environment);
        $('.mr-widget-body').before(template);
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
            this.setMergeButtonClass('btn-danger');
            break;
          case "running":
            this.setMergeButtonClass('btn-info');
            break;
          case "success":
          case "success_with_warnings":
            this.setMergeButtonClass('btn-create');
        }
      } else {
        $('.ci_widget.ci-error').show();
        this.setMergeButtonClass('btn-danger');
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

    MergeRequestWidget.prototype.updatePipelineUrls = function(id) {
      const pipelineUrl = this.opts.pipeline_path;
      $('.pipeline').text(`#${id}`).attr('href', [pipelineUrl, id].join('/'));
    };

    MergeRequestWidget.prototype.updateCommitUrls = function(id) {
      const commitsUrl = this.opts.commits_path;
      $('.js-commit-link').text(`#${id}`).attr('href', [commitsUrl, id].join('/'));
    };

    MergeRequestWidget.prototype.initMiniPipelineGraph = function() {
      new gl.MiniPipelineGraph({
        container: '.js-pipeline-inline-mr-widget-graph:visible',
      }).bindEvents();
    };

    return MergeRequestWidget;
  })();
})(window.gl || (window.gl = {}));

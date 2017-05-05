/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-use-before-define, camelcase, quotes, object-shorthand, no-shadow, no-unused-vars, comma-dangle, no-var, prefer-template, no-underscore-dangle, consistent-return, one-var, one-var-declaration-per-line, default-case, prefer-arrow-callback, max-len */
/* global Flash */
/* global Sortable */

(function() {
  this.Milestone = (function() {
    Milestone.updateIssue = function(li, issue_url, data) {
      return $.ajax({
        type: "PUT",
        url: issue_url,
        data: data,
        success: function(_data) {
          return Milestone.successCallback(_data, li);
        },
        error: function(data) {
          return new Flash("Issue update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.sortIssues = function(url, data) {
      return $.ajax({
        type: "PUT",
        url,
        data: data,
        success: function(_data) {
          return Milestone.successCallback(_data);
        },
        error: function() {
          return new Flash("Issues update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.sortMergeRequests = function(url, data) {
      return $.ajax({
        type: "PUT",
        url,
        data: data,
        success: function(_data) {
          return Milestone.successCallback(_data);
        },
        error: function(data) {
          return new Flash("Issue update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.updateMergeRequest = function(li, merge_request_url, data) {
      return $.ajax({
        type: "PUT",
        url: merge_request_url,
        data: data,
        success: function(_data) {
          return Milestone.successCallback(_data, li);
        },
        error: function(data) {
          return new Flash("Issue update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.successCallback = function(data, element) {
      var img_tag;
      if (data.assignee) {
        img_tag = $('<img/>');
        img_tag.attr('src', data.assignee.avatar_url);
        img_tag.addClass('avatar s16');
        $(element).find('.assignee-icon img').replaceWith(img_tag);
      } else {
        $(element).find('.assignee-icon').empty();
      }
    };

    function Milestone() {
      this.issuesSortEndpoint = $('#tab-issues').data('sort-endpoint');
      this.mergeRequestsSortEndpoint = $('#tab-merge-requests').data('sort-endpoint');

      this.bindIssuesSorting();
      this.bindTabsSwitching();

      // Load merge request tab if it is active
      // merge request tab is active based on different conditions in the backend
      this.loadTab($('.js-milestone-tabs .active a'));

      this.loadInitialTab();
    }

    Milestone.prototype.bindIssuesSorting = function() {
      if (!this.issuesSortEndpoint) return;

      $('#issues-list-unassigned, #issues-list-ongoing, #issues-list-closed').each(function (i, el) {
        this.createSortable(el, {
          group: 'issue-list',
          listEls: $('.issues-sortable-list'),
          fieldName: 'issue',
          sortCallback: (data) => {
            Milestone.sortIssues(this.issuesSortEndpoint, data);
          },
          updateCallback: Milestone.updateIssue,
        });
      }.bind(this));
    };

    Milestone.prototype.bindTabsSwitching = function() {
      return $('a[data-toggle="tab"]').on('show.bs.tab', (e) => {
        const $target = $(e.target);

        location.hash = $target.attr('href');
        this.loadTab($target);
      });
    };

    Milestone.prototype.bindMergeRequestSorting = function() {
      if (!this.mergeRequestsSortEndpoint) return;

      $("#merge_requests-list-unassigned, #merge_requests-list-ongoing, #merge_requests-list-closed").each(function (i, el) {
        this.createSortable(el, {
          group: 'merge-request-list',
          listEls: $(".merge_requests-sortable-list:not(#merge_requests-list-merged)"),
          fieldName: 'merge_request',
          sortCallback: (data) => {
            Milestone.sortMergeRequests(this.mergeRequestsSortEndpoint, data);
          },
          updateCallback: Milestone.updateMergeRequest,
        });
      }.bind(this));
    };

    Milestone.prototype.createSortable = function(el, opts) {
      return Sortable.create(el, {
        group: opts.group,
        filter: '.is-disabled',
        forceFallback: true,
        onStart: function(e) {
          opts.listEls.css('min-height', e.item.offsetHeight);
        },
        onEnd: function () {
          opts.listEls.css("min-height", "0px");
        },
        onUpdate: function(e) {
          var ids = this.toArray(),
            data;

          if (ids.length) {
            data = ids.map(function(id) {
              return 'sortable_' + opts.fieldName + '[]=' + id;
            }).join('&');

            opts.sortCallback(data);
          }
        },
        onAdd: function (e) {
          var data, issuableId, issuableUrl, newState;
          newState = e.to.dataset.state;
          issuableUrl = e.item.dataset.url;
          data = (function() {
            switch (newState) {
              case 'ongoing':
                return opts.fieldName + '[assignee_id]=' + gon.current_user_id;
              case 'unassigned':
                return opts.fieldName + '[assignee_id]=';
              case 'closed':
                return opts.fieldName + '[state_event]=close';
            }
          })();
          if (e.from.dataset.state === 'closed') {
            data += '&' + opts.fieldName + '[state_event]=reopen';
          }

          opts.updateCallback(e.item, issuableUrl, data);
          this.options.onUpdate.call(this, e);
        }
      });
    };

    Milestone.prototype.loadInitialTab = function() {
      const $target = $(`.js-milestone-tabs a[href="${location.hash}"]`);

      if ($target.length) {
        $target.tab('show');
      }
    };

    Milestone.prototype.loadTab = function($target) {
      const endpoint = $target.data('endpoint');
      const tabElId = $target.attr('href');

      if (endpoint && !$target.hasClass('is-loaded')) {
        $.ajax({
          url: endpoint,
          dataType: 'JSON',
        })
        .fail(() => new Flash('Error loading milestone tab'))
        .done((data) => {
          $(tabElId).html(data.html);
          $target.addClass('is-loaded');

          if (tabElId === '#tab-merge-requests') {
            this.bindMergeRequestSorting();
          }
        });
      }
    };

    return Milestone;
  })();
}).call(window);

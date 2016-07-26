(function() {
  this.Milestone = (function() {
    Milestone.updateIssue = function(li, issue_url, data) {
      return $.ajax({
        type: "PUT",
        url: issue_url,
        data: data,
        success: (function(_this) {
          return function(_data) {
            return _this.successCallback(_data, li);
          };
        })(this),
        error: function(data) {
          return new Flash("Issue update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.sortIssues = function(data) {
      var sort_issues_url;
      sort_issues_url = location.href + "/sort_issues";
      return $.ajax({
        type: "PUT",
        url: sort_issues_url,
        data: data,
        success: (function(_this) {
          return function(_data) {
            return _this.successCallback(_data);
          };
        })(this),
        error: function() {
          return new Flash("Issues update failed", 'alert');
        },
        dataType: "json"
      });
    };

    Milestone.sortMergeRequests = function(data) {
      var sort_mr_url;
      sort_mr_url = location.href + "/sort_merge_requests";
      return $.ajax({
        type: "PUT",
        url: sort_mr_url,
        data: data,
        success: (function(_this) {
          return function(_data) {
            return _this.successCallback(_data);
          };
        })(this),
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
        success: (function(_this) {
          return function(_data) {
            return _this.successCallback(_data, li);
          };
        })(this),
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
        $(element).find('.assignee-icon').html(img_tag);
      } else {
        $(element).find('.assignee-icon').html('');
      }
      return $(element).effect('highlight');
    };

    function Milestone() {
      var oldMouseStart;
      oldMouseStart = $.ui.sortable.prototype._mouseStart;
      $.ui.sortable.prototype._mouseStart = function(event, overrideHandle, noActivation) {
        this._trigger("beforeStart", event, this._uiHash());
        return oldMouseStart.apply(this, [event, overrideHandle, noActivation]);
      };
      this.bindIssuesSorting();
      this.bindMergeRequestSorting();
      this.bindTabsSwitching();
    }

    Milestone.prototype.bindIssuesSorting = function() {
      return $("#issues-list-unassigned, #issues-list-ongoing, #issues-list-closed").sortable({
        connectWith: ".issues-sortable-list",
        dropOnEmpty: true,
        items: "li:not(.ui-sort-disabled)",
        beforeStart: function(event, ui) {
          return $(".issues-sortable-list").css("min-height", ui.item.outerHeight());
        },
        stop: function(event, ui) {
          return $(".issues-sortable-list").css("min-height", "0px");
        },
        update: function(event, ui) {
          var data;
          // Prevents sorting from container which element has been removed.
          if ($(this).find(ui.item).length > 0) {
            data = $(this).sortable("serialize");
            return Milestone.sortIssues(data);
          }
        },
        receive: function(event, ui) {
          var data, issue_id, issue_url, new_state;
          new_state = $(this).data('state');
          issue_id = ui.item.data('iid');
          issue_url = ui.item.data('url');
          data = (function() {
            switch (new_state) {
              case 'ongoing':
                return "issue[assignee_id]=" + gon.current_user_id;
              case 'unassigned':
                return "issue[assignee_id]=";
              case 'closed':
                return "issue[state_event]=close";
            }
          })();
          if ($(ui.sender).data('state') === "closed") {
            data += "&issue[state_event]=reopen";
          }
          return Milestone.updateIssue(ui.item, issue_url, data);
        }
      }).disableSelection();
    };

    Milestone.prototype.bindTabsSwitching = function() {
      return $('a[data-toggle="tab"]').on('show.bs.tab', function(e) {
        var currentTabClass, previousTabClass;
        currentTabClass = $(e.target).data('show');
        previousTabClass = $(e.relatedTarget).data('show');
        $(previousTabClass).hide();
        $(currentTabClass).removeClass('hidden');
        return $(currentTabClass).show();
      });
    };

    Milestone.prototype.bindMergeRequestSorting = function() {
      return $("#merge_requests-list-unassigned, #merge_requests-list-ongoing, #merge_requests-list-closed").sortable({
        connectWith: ".merge_requests-sortable-list",
        dropOnEmpty: true,
        items: "li:not(.ui-sort-disabled)",
        beforeStart: function(event, ui) {
          return $(".merge_requests-sortable-list").css("min-height", ui.item.outerHeight());
        },
        stop: function(event, ui) {
          return $(".merge_requests-sortable-list").css("min-height", "0px");
        },
        update: function(event, ui) {
          var data;
          data = $(this).sortable("serialize");
          return Milestone.sortMergeRequests(data);
        },
        receive: function(event, ui) {
          var data, merge_request_id, merge_request_url, new_state;
          new_state = $(this).data('state');
          merge_request_id = ui.item.data('iid');
          merge_request_url = ui.item.data('url');
          data = (function() {
            switch (new_state) {
              case 'ongoing':
                return "merge_request[assignee_id]=" + gon.current_user_id;
              case 'unassigned':
                return "merge_request[assignee_id]=";
              case 'closed':
                return "merge_request[state_event]=close";
            }
          })();
          if ($(ui.sender).data('state') === "closed") {
            data += "&merge_request[state_event]=reopen";
          }
          return Milestone.updateMergeRequest(ui.item, merge_request_url, data);
        }
      }).disableSelection();
    };

    return Milestone;

  })();

  window.gl.Dispatcher.register([
    'projects:milestones:show',
    'groups:milestones:show',
    'dashboard:milestones:show'
  ], this.Milestone);

}).call(this);

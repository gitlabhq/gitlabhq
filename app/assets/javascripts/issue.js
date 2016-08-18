
/*= require flash */


/*= require jquery.waitforimages */


/*= require task_list */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Issue = (function() {
    function Issue() {
      this.submitNoteForm = bind(this.submitNoteForm, this);
      this.disableTaskList();
      if ($('a.btn-close').length) {
        this.initTaskList();
        this.initIssueBtnEventListeners();
      }
      this.initMergeRequests();
      this.initRelatedBranches();
      this.initCanCreateBranch();
    }

    Issue.prototype.initTaskList = function() {
      $('.detail-page-description .js-task-list-container').taskList('enable');
      return $(document).on('tasklist:changed', '.detail-page-description .js-task-list-container', this.updateTaskList);
    };

    Issue.prototype.initIssueBtnEventListeners = function() {
      var _this, issueFailMessage;
      _this = this;
      issueFailMessage = 'Unable to update this issue at this time.';
      return $('a.btn-close, a.btn-reopen').on('click', function(e) {
        var $this, isClose, shouldSubmit, url;
        e.preventDefault();
        e.stopImmediatePropagation();
        $this = $(this);
        isClose = $this.hasClass('btn-close');
        shouldSubmit = $this.hasClass('btn-comment');
        if (shouldSubmit) {
          _this.submitNoteForm($this.closest('form'));
        }
        $this.prop('disabled', true);
        url = $this.attr('href');
        return $.ajax({
          type: 'PUT',
          url: url,
          error: function(jqXHR, textStatus, errorThrown) {
            var issueStatus;
            issueStatus = isClose ? 'close' : 'open';
            return new Flash(issueFailMessage, 'alert');
          },
          success: function(data, textStatus, jqXHR) {
            if ('id' in data) {
              $(document).trigger('issuable:change');
              if (isClose) {
                $('a.btn-close').addClass('hidden');
                $('a.btn-reopen').removeClass('hidden');
                $('div.status-box-closed').removeClass('hidden');
                $('div.status-box-open').addClass('hidden');
              } else {
                $('a.btn-reopen').addClass('hidden');
                $('a.btn-close').removeClass('hidden');
                $('div.status-box-closed').addClass('hidden');
                $('div.status-box-open').removeClass('hidden');
              }
            } else {
              new Flash(issueFailMessage, 'alert');
            }
            return $this.prop('disabled', false);
          }
        });
      });
    };

    Issue.prototype.submitNoteForm = function(form) {
      var noteText;
      noteText = form.find("textarea.js-note-text").val();
      if (noteText.trim().length > 0) {
        return form.submit();
      }
    };

    Issue.prototype.disableTaskList = function() {
      $('.detail-page-description .js-task-list-container').taskList('disable');
      return $(document).off('tasklist:changed', '.detail-page-description .js-task-list-container');
    };

    Issue.prototype.updateTaskList = function() {
      var patchData;
      patchData = {};
      patchData['issue'] = {
        'description': $('.js-task-list-field', this).val()
      };
      return $.ajax({
        type: 'PATCH',
        url: $('form.js-issuable-update').attr('action'),
        data: patchData
      });
    };

    Issue.prototype.initMergeRequests = function() {
      var $container;
      $container = $('#merge-requests');
      return $.getJSON($container.data('url')).error(function() {
        return new Flash('Failed to load referenced merge requests', 'alert');
      }).success(function(data) {
        if ('html' in data) {
          return $container.html(data.html);
        }
      });
    };

    Issue.prototype.initRelatedBranches = function() {
      var $container;
      $container = $('#related-branches');
      return $.getJSON($container.data('url')).error(function() {
        return new Flash('Failed to load related branches', 'alert');
      }).success(function(data) {
        if ('html' in data) {
          return $container.html(data.html);
        }
      });
    };

    Issue.prototype.initCanCreateBranch = function() {
      var $container;
      $container = $('#new-branch');
      if ($container.length === 0) {
        return;
      }
      return $.getJSON($container.data('path')).error(function() {
        $container.find('.checking').hide();
        $container.find('.unavailable').show();
        return new Flash('Failed to check if a new branch can be created.', 'alert');
      }).success(function(data) {
        if (data.can_create_branch) {
          $container.find('.checking').hide();
          $container.find('.available').show();
        } else {
          $container.find('.checking').hide();
          return $container.find('.unavailable').show();
        }
      });
    };

    return Issue;

  })();

}).call(this);

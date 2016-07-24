
/*= require jquery.waitforimages */


/*= require task_list */


/*= require merge_request_tabs */

(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.MergeRequest = (function() {
    function MergeRequest(opts) {
      this.opts = opts != null ? opts : {};
      this.submitNoteForm = bind(this.submitNoteForm, this);
      this.$el = $('.merge-request');
      this.$('.show-all-commits').on('click', (function(_this) {
        return function() {
          return _this.showAllCommits();
        };
      })(this));
      this.initTabs();
      this.disableTaskList();
      this.initMRBtnListeners();
      if ($("a.btn-close").length) {
        this.initTaskList();
      }
    }

    MergeRequest.prototype.$ = function(selector) {
      return this.$el.find(selector);
    };

    MergeRequest.prototype.initTabs = function() {
      if (this.opts.action !== 'new') {
        return new MergeRequestTabs(this.opts);
      } else {
        return $('.merge-request-tabs a[data-toggle="tab"]:first').tab('show');
      }
    };

    MergeRequest.prototype.showAllCommits = function() {
      this.$('.first-commits').remove();
      return this.$('.all-commits').removeClass('hide');
    };

    MergeRequest.prototype.initTaskList = function() {
      $('.detail-page-description .js-task-list-container').taskList('enable');
      return $(document).on('tasklist:changed', '.detail-page-description .js-task-list-container', this.updateTaskList);
    };

    MergeRequest.prototype.initMRBtnListeners = function() {
      var _this;
      _this = this;
      return $('a.btn-close, a.btn-reopen').on('click', function(e) {
        var $this, shouldSubmit;
        $this = $(this);
        shouldSubmit = $this.hasClass('btn-comment');
        if (shouldSubmit && $this.data('submitted')) {
          return;
        }
        if (shouldSubmit) {
          if ($this.hasClass('btn-comment-and-close') || $this.hasClass('btn-comment-and-reopen')) {
            e.preventDefault();
            e.stopImmediatePropagation();
            return _this.submitNoteForm($this.closest('form'), $this);
          }
        }
      });
    };

    MergeRequest.prototype.submitNoteForm = function(form, $button) {
      var noteText;
      noteText = form.find("textarea.js-note-text").val();
      if (noteText.trim().length > 0) {
        form.submit();
        $button.data('submitted', true);
        return $button.trigger('click');
      }
    };

    MergeRequest.prototype.disableTaskList = function() {
      $('.detail-page-description .js-task-list-container').taskList('disable');
      return $(document).off('tasklist:changed', '.detail-page-description .js-task-list-container');
    };

    MergeRequest.prototype.updateTaskList = function() {
      var patchData;
      patchData = {};
      patchData['merge_request'] = {
        'description': $('.js-task-list-field', this).val()
      };
      return $.ajax({
        type: 'PATCH',
        url: $('form.js-issuable-update').attr('action'),
        data: patchData
      });
    };

    return MergeRequest;

  })();

}).call(this);

/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, quotes, no-underscore-dangle, one-var, one-var-declaration-per-line, consistent-return, dot-notation, quote-props, comma-dangle, object-shorthand, max-len, prefer-arrow-callback */
/* global MergeRequestTabs */
/* global Issuable */

require('vendor/jquery.waitforimages');
require('./task_list');
require('./merge_request_tabs');

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  this.MergeRequest = (function() {
    function MergeRequest(opts) {
      // Initialize MergeRequest behavior
      //
      // Options:
      //   action - String, current controller action
      //
      this.opts = opts != null ? opts : {};
      this.submitNoteForm = bind(this.submitNoteForm, this);
      this.$el = $('.merge-request');
      this.$('.show-all-commits').on('click', (function(_this) {
        return function() {
          return _this.showAllCommits();
        };
      })(this));

      this.initTabs();
      this.initCommitMessageListeners();

      if ($("a.btn-close").length) {
        this.taskList = new gl.TaskList({
          dataType: 'merge_request',
          fieldName: 'description',
          selector: '.detail-page-description',
          onSuccess: (result) => {
            document.querySelector('#task_status').innerText = result.task_status;
            document.querySelector('#task_status_short').innerText = result.task_status_short;
          }
        });

        Issuable.initStateChangeButton({
          type: 'merge request',
          callback() {
            gl.utils.visitUrl(location.href);
          },
        });
      }
    }

    // Local jQuery finder
    MergeRequest.prototype.$ = function(selector) {
      return this.$el.find(selector);
    };

    MergeRequest.prototype.initTabs = function() {
      if (window.mrTabs) {
        window.mrTabs.unbindEvents();
      }
      window.mrTabs = new gl.MergeRequestTabs(this.opts);
    };

    MergeRequest.prototype.showAllCommits = function() {
      this.$('.first-commits').remove();
      return this.$('.all-commits').removeClass('hide');
    };

    MergeRequest.prototype.initCommitMessageListeners = function() {
      $(document).on('click', 'a.js-with-description-link', function(e) {
        var textarea = $('textarea.js-commit-message');
        e.preventDefault();

        textarea.val(textarea.data('messageWithDescription'));
        $('.js-with-description-hint').hide();
        $('.js-without-description-hint').show();
      });

      $(document).on('click', 'a.js-without-description-link', function(e) {
        var textarea = $('textarea.js-commit-message');
        e.preventDefault();

        textarea.val(textarea.data('messageWithoutDescription'));
        $('.js-with-description-hint').show();
        $('.js-without-description-hint').hide();
      });
    };

    return MergeRequest;
  })();
}).call(window);

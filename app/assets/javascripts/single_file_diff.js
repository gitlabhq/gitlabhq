/* eslint-disable func-names, prefer-arrow-callback, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, one-var-declaration-per-line, consistent-return, no-param-reassign, max-len */

import BlobViewer from './blob/viewer';

(function() {
  window.SingleFileDiff = (function() {
    var COLLAPSED_HTML, ERROR_HTML, LOADING_HTML, WRAPPER;

    WRAPPER = '<div class="diff-content"></div>';

    LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>';

    ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>';

    COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. <a class="click-to-expand">Click to expand it.</a></div>';

    function SingleFileDiff(file) {
      this.file = file;
      this.toggleDiff = this.toggleDiff.bind(this);
      this.switcherBtns = $('.js-diff-viewer-switch-btn', this.file);
      this.viewers = $('.diff-viewer', this.file);
      this.content = $('.diff-content', this.file);
      this.$toggleIcon = $('.diff-toggle-caret', this.file);
      this.diffForPath = this.content.find('[data-diff-for-path]').data('diff-for-path');
      this.isOpen = !this.diffForPath;
      if (this.diffForPath) {
        this.collapsedContent = this.content;
        this.loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide();
        this.content = null;
        this.collapsedContent.after(this.loadingContent);
        this.$toggleIcon.addClass('fa-caret-right');
        this.switcherBtns.disable();
      } else {
        this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
        this.content.after(this.collapsedContent);
        this.$toggleIcon.addClass('fa-caret-down');
        this.switcherBtns.filter('[data-viewer="rich"]').toggleClass('active');
      }

      $('.js-file-title, .click-to-expand', this.file).on('click', (function (e) {
        this.toggleDiff($(e.target));
      }).bind(this));

      this.viewer = new BlobViewer(this.file, 'diff');
    }

    SingleFileDiff.prototype.toggleDiff = function($target, cb) {
      if (!$target.hasClass('js-file-title') && !$target.hasClass('click-to-expand') && !$target.hasClass('diff-toggle-caret')) return;
      this.isOpen = !this.isOpen;
      if (!this.isOpen && !this.hasError) {
        this.content.hide();
        this.$toggleIcon.addClass('fa-caret-right').removeClass('fa-caret-down');
        this.collapsedContent.show();
        if (typeof gl.diffNotesCompileComponents !== 'undefined') {
          gl.diffNotesCompileComponents();
        }
      } else if (this.content) {
        this.collapsedContent.hide();
        this.content.show();
        this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
        if (typeof gl.diffNotesCompileComponents !== 'undefined') {
          gl.diffNotesCompileComponents();
        }
      } else {
        this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
        return this.getContentHTML(cb);
      }
    };

    SingleFileDiff.prototype.getContentHTML = function(cb) {
      this.collapsedContent.hide();
      this.loadingContent.show();
      $.get(this.diffForPath, (data) => {
        this.loadingContent.hide();
        if (data.html) {
          const content = $(data.html);
          content.syntaxHighlight();

          this.viewers.replaceWith(function() {
            return content.find(`[data-type="${$(this).attr('data-type')}"]`);
          });

          this.collapsedContent.show();

          this.switcherBtns.enable();
          this.viewer.switchToInitialViewer();
        } else {
          this.hasError = true;
          this.collapsedContent.after(ERROR_HTML);
        }

        if (typeof gl.diffNotesCompileComponents !== 'undefined') {
          gl.diffNotesCompileComponents();
        }

        if (cb) cb();
      });
    };

    return SingleFileDiff;
  })();

  $.fn.singleFileDiff = function() {
    return this.each(function() {
      if (!$.data(this, 'singleFileDiff')) {
        return $.data(this, 'singleFileDiff', new window.SingleFileDiff(this));
      }
    });
  };
}).call(window);

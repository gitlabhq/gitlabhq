/* eslint-disable func-names, prefer-arrow-callback, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, one-var, one-var-declaration-per-line, consistent-return, no-param-reassign, max-len */

(function() {
  var bind = function(fn, me) { return function() { return fn.apply(me, arguments); }; };

  window.SingleFileDiff = (function() {
    var COLLAPSED_HTML, ERROR_HTML, LOADING_HTML, WRAPPER;

    WRAPPER = '<div class="diff-content diff-wrap-lines"></div>';

    LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>';

    ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>';

    COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. <a class="click-to-expand">Click to expand it.</a></div>';

    function SingleFileDiff(file) {
      this.file = file;
      this.toggleDiff = bind(this.toggleDiff, this);
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
      } else {
        this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
        this.content.after(this.collapsedContent);
        this.$toggleIcon.addClass('fa-caret-down');
      }

      $('.js-file-title, .click-to-expand', this.file).on('click', (function (e) {
        this.toggleDiff($(e.target));
      }).bind(this));
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
      $.get(this.diffForPath, (function(_this) {
        return function(data) {
          _this.loadingContent.hide();
          if (data.html) {
            _this.content = $(data.html);
            _this.content.syntaxHighlight();
          } else {
            _this.hasError = true;
            _this.content = $(ERROR_HTML);
          }
          _this.collapsedContent.after(_this.content);

          if (typeof gl.diffNotesCompileComponents !== 'undefined') {
            gl.diffNotesCompileComponents();
          }

          if (cb) cb();
        };
      })(this));
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

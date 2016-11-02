/* eslint-disable */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.SingleFileDiff = (function() {
    var COLLAPSED_HTML, ERROR_HTML, LOADING_HTML, WRAPPER;

    WRAPPER = '<div class="diff-content diff-wrap-lines"></div>';

    LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>';

    ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>';

    COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. <a class="click-to-expand">Click to expand it.</a></div>';

    function SingleFileDiff(file, forceLoad, cb) {
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
      $('.file-title, .click-to-expand', this.file).on('click', this.toggleDiff);
      if (forceLoad) {
        this.toggleDiff(null, cb);
      }
    }

    SingleFileDiff.prototype.toggleDiff = function(e, cb) {
      var $target = $(e.target);
      if (!$target.hasClass('file-title') && !$target.hasClass('click-to-expand') && !$target.hasClass('diff-toggle-caret')) return;
      this.isOpen = !this.isOpen;
      if (!this.isOpen && !this.hasError) {
        this.content.hide();
        this.$toggleIcon.addClass('fa-caret-right').removeClass('fa-caret-down');
        this.collapsedContent.show();
        if (typeof DiffNotesApp !== 'undefined') {
          DiffNotesApp.compileComponents();
        }
      } else if (this.content) {
        this.collapsedContent.hide();
        this.content.show();
        this.$toggleIcon.addClass('fa-caret-down').removeClass('fa-caret-right');
        if (typeof DiffNotesApp !== 'undefined') {
          DiffNotesApp.compileComponents();
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

          if (typeof DiffNotesApp !== 'undefined') {
            DiffNotesApp.compileComponents();
          }

          if (cb) cb();
        };
      })(this));
    };

    return SingleFileDiff;

  })();

  $.fn.singleFileDiff = function(forceLoad, cb) {
    return this.each(function() {
      if (!$.data(this, 'singleFileDiff') || forceLoad) {
        return $.data(this, 'singleFileDiff', new SingleFileDiff(this, forceLoad, cb));
      }
    });
  };

}).call(this);

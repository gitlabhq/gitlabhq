(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.SingleFileDiff = (function() {
    var COLLAPSED_HTML, ERROR_HTML, LOADING_HTML, WRAPPER;

    WRAPPER = '<div class="diff-content diff-wrap-lines"></div>';

    LOADING_HTML = '<i class="fa fa-spinner fa-spin"></i>';

    ERROR_HTML = '<div class="nothing-here-block"><i class="fa fa-warning"></i> Could not load diff</div>';

    COLLAPSED_HTML = '<div class="nothing-here-block diff-collapsed">This diff is collapsed. Click to expand it.</div>';

    function SingleFileDiff(file) {
      this.file = file;
      this.toggleDiff = bind(this.toggleDiff, this);
      this.content = $('.diff-content', this.file);
      this.diffForPath = this.content.find('[data-diff-for-path]').data('diff-for-path');
      this.isOpen = !this.diffForPath;
      if (this.diffForPath) {
        this.collapsedContent = this.content;
        this.loadingContent = $(WRAPPER).addClass('loading').html(LOADING_HTML).hide();
        this.content = null;
        this.collapsedContent.after(this.loadingContent);
      } else {
        this.collapsedContent = $(WRAPPER).html(COLLAPSED_HTML).hide();
        this.content.after(this.collapsedContent);
      }
      this.collapsedContent.on('click', this.toggleDiff);
      $('.file-title > a', this.file).on('click', this.toggleDiff);
    }

    SingleFileDiff.prototype.toggleDiff = function(e) {
      this.isOpen = !this.isOpen;
      if (!this.isOpen && !this.hasError) {
        this.content.hide();
        this.collapsedContent.show();
        if (DiffNotesApp) {
          DiffNotesApp.compileComponents();
        }
      } else if (this.content) {
        this.collapsedContent.hide();
        this.content.show();
        if (DiffNotesApp) {
          DiffNotesApp.compileComponents();
        }
      } else {
        return this.getContentHTML();
      }
    };

    SingleFileDiff.prototype.getContentHTML = function() {
      this.collapsedContent.hide();
      this.loadingContent.show();
      $.get(this.diffForPath, (function(_this) {
        return function(data) {
          _this.loadingContent.hide();
          if (data.html) {
            _this.content = $(data.html);
            _this.content.syntaxHighlight();
            if (DiffNotesApp) {
              DiffNotesApp.compileComponents();
            }
          } else {
            _this.hasError = true;
            _this.content = $(ERROR_HTML);
          }
          return _this.collapsedContent.after(_this.content);
        };
      })(this));
    };

    return SingleFileDiff;

  })();

  $.fn.singleFileDiff = function() {
    return this.each(function() {
      if (!$.data(this, 'singleFileDiff')) {
        return $.data(this, 'singleFileDiff', new SingleFileDiff(this));
      }
    });
  };

}).call(this);

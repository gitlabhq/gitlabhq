/* eslint-disable func-names, space-before-function-paren, wrap-iife, prefer-arrow-callback, no-unused-vars, consistent-return, camelcase, comma-dangle, padded-blocks, max-len, no-var */
/* global Dropzone */
/* global Mousetrap */

// Zen Mode (full screen) textarea
//
/*= provides zen_mode:enter */
/*= provides zen_mode:leave */
//
/*= require jquery.scrollTo */
/*= require dropzone */
/*= require mousetrap */
/*= require mousetrap/pause */

//
// ### Events
//
// `zen_mode:enter`
//
// Fired when the "Edit in fullscreen" link is clicked.
//
// **Synchronicity** Sync
// **Bubbles** Yes
// **Cancelable** No
// **Target** a.js-zen-enter
//
// `zen_mode:leave`
//
// Fired when the "Leave Fullscreen" link is clicked.
//
// **Synchronicity** Sync
// **Bubbles** Yes
// **Cancelable** No
// **Target** a.js-zen-leave
//
(function() {
  this.ZenMode = (function() {
    function ZenMode() {
      var $document = $(document);

      this.active_backdrop = null;
      this.active_textarea = null;

      $document.off('click.zenEnter').on('click.zenEnter', '.js-zen-enter', function(e) {
        e.preventDefault();
        return $(e.currentTarget).trigger('zen_mode:enter');
      });
      $document.off('click.zenLeave').on('click.zenLeave', '.js-zen-leave', function(e) {
        e.preventDefault();
        return $(e.currentTarget).trigger('zen_mode:leave');
      });
      $document.off('zen_mode:enter.zenBackdrop').on('zen_mode:enter.zenBackdrop', (function(_this) {
        return function(e) {
          return _this.enter($(e.target).closest('.md-area').find('.zen-backdrop'));
        };
      })(this));
      $document.off('zen_mode:leave.exit').on('zen_mode:leave.exit', (function(_this) {
        return function(e) {
          return _this.exit();
        };
      })(this));
      $document.off('keydown.zenEscape').on('keydown.zenEscape', function(e) {
        // Esc
        if (e.keyCode === 27) {
          e.preventDefault();
          return $document.trigger('zen_mode:leave');
        }
      });
    }

    ZenMode.prototype.enter = function(backdrop) {
      Mousetrap.pause();
      this.active_backdrop = $(backdrop);
      this.active_backdrop.addClass('fullscreen');
      this.active_textarea = this.active_backdrop.find('textarea');
      // Prevent a user-resized textarea from persisting to fullscreen
      this.active_textarea.removeAttr('style');
      return this.active_textarea.focus();
    };

    ZenMode.prototype.exit = function() {
      if (this.active_textarea) {
        Mousetrap.unpause();
        this.active_textarea.closest('.zen-backdrop').removeClass('fullscreen');
        this.scrollTo(this.active_textarea);
        this.active_textarea = null;
        this.active_backdrop = null;
        return Dropzone.forElement('.div-dropzone').enable();
      }
    };

    ZenMode.prototype.scrollTo = function(zen_area) {
      return $.scrollTo(zen_area, 0, {
        offset: -150
      });
    };

    return ZenMode;

  })();

}).call(this);

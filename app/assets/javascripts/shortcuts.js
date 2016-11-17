/* eslint-disable func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, quotes, no-undef, prefer-arrow-callback, consistent-return, object-shorthand, no-unused-vars, one-var, one-var-declaration-per-line, no-plusplus, no-else-return, comma-dangle, padded-blocks, max-len */
(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.Shortcuts = (function() {
    function Shortcuts(skipResetBindings) {
      this.onToggleHelp = bind(this.onToggleHelp, this);
      this.enabledHelp = [];
      if (!skipResetBindings) {
        Mousetrap.reset();
      }
      Mousetrap.bind('?', this.onToggleHelp);
      Mousetrap.bind('s', Shortcuts.focusSearch);
      Mousetrap.bind('f', (function(_this) {
        return function(e) {
          return _this.focusFilter(e);
        };
      })(this));
      Mousetrap.bind(['ctrl+shift+p', 'command+shift+p'], this.toggleMarkdownPreview);
      if (typeof findFileURL !== "undefined" && findFileURL !== null) {
        Mousetrap.bind('t', function() {
          return Turbolinks.visit(findFileURL);
        });
      }
    }

    Shortcuts.prototype.onToggleHelp = function(e) {
      e.preventDefault();
      return Shortcuts.toggleHelp(this.enabledHelp);
    };

    Shortcuts.prototype.toggleMarkdownPreview = function(e) {
      return $(document).triggerHandler('markdown-preview:toggle', [e]);
    };

    Shortcuts.toggleHelp = function(location) {
      var $modal;
      $modal = $('#modal-shortcuts');
      if ($modal.length) {
        $modal.modal('toggle');
        return;
      }
      return $.ajax({
        url: gon.shortcuts_path,
        dataType: 'script',
        success: function(e) {
          var i, l, len, results;
          if (location && location.length > 0) {
            results = [];
            for (i = 0, len = location.length; i < len; i++) {
              l = location[i];
              results.push($(l).show());
            }
            return results;
          } else {
            $('.hidden-shortcut').show();
            return $('.js-more-help-button').remove();
          }
        }
      });
    };

    Shortcuts.prototype.focusFilter = function(e) {
      if (this.filterInput == null) {
        this.filterInput = $('input[type=search]', '.nav-controls');
      }
      this.filterInput.focus();
      return e.preventDefault();
    };

    Shortcuts.focusSearch = function(e) {
      $('#search').focus();
      return e.preventDefault();
    };

    return Shortcuts;

  })();

  $(document).on('click.more_help', '.js-more-help-button', function(e) {
    $(this).remove();
    $('.hidden-shortcut').show();
    return e.preventDefault();
  });

  Mousetrap.stopCallback = (function() {
    var defaultStopCallback;
    defaultStopCallback = Mousetrap.stopCallback;
    return function(e, element, combo) {
      // allowed shortcuts if textarea, input, contenteditable are focused
      if (['ctrl+shift+p', 'command+shift+p'].indexOf(combo) !== -1) {
        return false;
      } else {
        return defaultStopCallback.apply(this, arguments);
      }
    };
  })();

}).call(this);

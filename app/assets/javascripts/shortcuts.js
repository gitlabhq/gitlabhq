/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, quotes, prefer-arrow-callback, consistent-return, object-shorthand, no-unused-vars, one-var, one-var-declaration-per-line, no-else-return, comma-dangle, max-len */
/* global Mousetrap */
import Cookies from 'js-cookie';

import findAndFollowLink from './shortcuts_dashboard_navigation';

(function() {
  this.Shortcuts = (function() {
    function Shortcuts(skipResetBindings) {
      this.onToggleHelp = this.onToggleHelp.bind(this);
      this.enabledHelp = [];
      if (!skipResetBindings) {
        Mousetrap.reset();
      }
      Mousetrap.bind('?', this.onToggleHelp);
      Mousetrap.bind('s', Shortcuts.focusSearch);
      Mousetrap.bind('f', (e => this.focusFilter(e)));
      Mousetrap.bind('p b', this.onTogglePerfBar);

      const $globalDropdownMenu = $('.global-dropdown-menu');
      const $globalDropdownToggle = $('.global-dropdown-toggle');
      const findFileURL = document.body.dataset.findFile;

      $('.global-dropdown').on('hide.bs.dropdown', () => {
        $globalDropdownMenu.removeClass('shortcuts');
      });

      Mousetrap.bind('n', () => {
        $globalDropdownMenu.toggleClass('shortcuts');
        $globalDropdownToggle.trigger('click');

        if (!$globalDropdownMenu.is(':visible')) {
          $globalDropdownToggle.blur();
        }
      });

      Mousetrap.bind('shift+t', () => findAndFollowLink('.shortcuts-todos'));
      Mousetrap.bind('shift+a', () => findAndFollowLink('.dashboard-shortcuts-activity'));
      Mousetrap.bind('shift+i', () => findAndFollowLink('.dashboard-shortcuts-issues'));
      Mousetrap.bind('shift+m', () => findAndFollowLink('.dashboard-shortcuts-merge_requests'));
      Mousetrap.bind('shift+p', () => findAndFollowLink('.dashboard-shortcuts-projects'));
      Mousetrap.bind('shift+g', () => findAndFollowLink('.dashboard-shortcuts-groups'));
      Mousetrap.bind('shift+l', () => findAndFollowLink('.dashboard-shortcuts-milestones'));
      Mousetrap.bind('shift+s', () => findAndFollowLink('.dashboard-shortcuts-snippets'));

      Mousetrap.bind(['ctrl+shift+p', 'command+shift+p'], this.toggleMarkdownPreview);
      if (typeof findFileURL !== "undefined" && findFileURL !== null) {
        Mousetrap.bind('t', function() {
          return gl.utils.visitUrl(findFileURL);
        });
      }
    }

    Shortcuts.prototype.onToggleHelp = function(e) {
      e.preventDefault();
      return Shortcuts.toggleHelp(this.enabledHelp);
    };

    Shortcuts.prototype.onTogglePerfBar = function(e) {
      e.preventDefault();
      const performanceBarCookieName = 'perf_bar_enabled';
      if (Cookies.get(performanceBarCookieName) === 'true') {
        Cookies.remove(performanceBarCookieName, { path: '/' });
      } else {
        Cookies.set(performanceBarCookieName, 'true', { path: '/' });
      }
      gl.utils.refreshCurrentPage();
    };

    Shortcuts.prototype.toggleMarkdownPreview = function(e) {
      // Check if short-cut was triggered while in Write Mode
      const $target = $(e.target);
      const $form = $target.closest('form');

      if ($target.hasClass('js-note-text')) {
        $('.js-md-preview-button', $form).focus();
      }
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
            for (i = 0, len = location.length; i < len; i += 1) {
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
}).call(window);

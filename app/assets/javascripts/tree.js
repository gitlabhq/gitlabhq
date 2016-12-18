/* eslint-disable func-names, space-before-function-paren, wrap-iife, max-len, quotes, consistent-return, no-var, one-var, one-var-declaration-per-line, no-else-return, prefer-arrow-callback, padded-blocks, max-len */
/* global Turbolinks */
(function() {
  this.TreeView = (function() {
    function TreeView() {
      this.initKeyNav();
      // Code browser tree slider
      // Make the entire tree-item row clickable, but not if clicking another link (like a commit message)
      $(".tree-content-holder .tree-item").on('click', function(e) {
        var $clickedEl, path;
        $clickedEl = $(e.target);
        path = $('.tree-item-file-name a', this).attr('href');
        if (!$clickedEl.is('a') && !$clickedEl.is('.str-truncated')) {
          if (e.metaKey || e.which === 2) {
            e.preventDefault();
            return window.open(path, '_blank');
          } else {
            return Turbolinks.visit(path);
          }
        }
      });
      // Show the "Loading commit data" for only the first element
      $('span.log_loading:first').removeClass('hide');
    }

    TreeView.prototype.initKeyNav = function() {
      var li, liSelected;
      li = $("tr.tree-item");
      liSelected = null;
      return $('body').keydown(function(e) {
        var next, path;
        if ($("input:focus").length > 0 && (e.which === 38 || e.which === 40)) {
          return false;
        }
        if (e.which === 40) {
          if (liSelected) {
            next = liSelected.next();
            if (next.length > 0) {
              liSelected.removeClass("selected");
              liSelected = next.addClass("selected");
            }
          } else {
            liSelected = li.eq(0).addClass("selected");
          }
          return $(liSelected).focus();
        } else if (e.which === 38) {
          if (liSelected) {
            next = liSelected.prev();
            if (next.length > 0) {
              liSelected.removeClass("selected");
              liSelected = next.addClass("selected");
            }
          } else {
            liSelected = li.last().addClass("selected");
          }
          return $(liSelected).focus();
        } else if (e.which === 13) {
          path = $('.tree-item.selected .tree-item-file-name a').attr('href');
          if (path) {
            return Turbolinks.visit(path);
          }
        }
      });
    };

    return TreeView;

  })();

}).call(this);

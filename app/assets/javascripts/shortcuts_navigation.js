(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsNavigation = (function(superClass) {
    extend(ShortcutsNavigation, superClass);

    function ShortcutsNavigation() {
      ShortcutsNavigation.__super__.constructor.call(this);
      Mousetrap.bind('g p', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-project');
      });
      Mousetrap.bind('g e', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-project-activity');
      });
      Mousetrap.bind('g f', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-tree');
      });
      Mousetrap.bind('g c', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-commits');
      });
      Mousetrap.bind('g b', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-builds');
      });
      Mousetrap.bind('g n', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-network');
      });
      Mousetrap.bind('g g', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-graphs');
      });
      Mousetrap.bind('g i', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-issues');
      });
      Mousetrap.bind('g m', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-merge_requests');
      });
      Mousetrap.bind('g w', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-wiki');
      });
      Mousetrap.bind('g s', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-snippets');
      });
      Mousetrap.bind('i', function() {
        return ShortcutsNavigation.findAndFollowLink('.shortcuts-new-issue');
      });
      this.enabledHelp.push('.hidden-shortcut.project');
    }

    ShortcutsNavigation.findAndFollowLink = function(selector) {
      var link;
      link = $(selector).attr('href');
      if (link) {
        return window.location = link;
      }
    };

    return ShortcutsNavigation;

  })(Shortcuts);

}).call(this);

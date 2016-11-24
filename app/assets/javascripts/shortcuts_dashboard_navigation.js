/* eslint-disable func-names, space-before-function-paren, max-len, one-var, no-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, prefer-arrow-callback, consistent-return, no-return-assign, padded-blocks, no-undef, max-len */

/*= require shortcuts */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsDashboardNavigation = (function(superClass) {
    extend(ShortcutsDashboardNavigation, superClass);

    function ShortcutsDashboardNavigation() {
      ShortcutsDashboardNavigation.__super__.constructor.call(this);
      Mousetrap.bind('g a', function() {
        return ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-activity');
      });
      Mousetrap.bind('g i', function() {
        return ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-issues');
      });
      Mousetrap.bind('g m', function() {
        return ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-merge_requests');
      });
      Mousetrap.bind('g p', function() {
        return ShortcutsDashboardNavigation.findAndFollowLink('.dashboard-shortcuts-projects');
      });
    }

    ShortcutsDashboardNavigation.findAndFollowLink = function(selector) {
      var link;
      link = $(selector).attr('href');
      if (link) {
        return window.location = link;
      }
    };

    return ShortcutsDashboardNavigation;

  })(Shortcuts);

}).call(this);

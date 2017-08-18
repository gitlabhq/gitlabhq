/* eslint-disable func-names, space-before-function-paren, max-len, no-var, one-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, prefer-arrow-callback, consistent-return, no-return-assign */
/* global Mousetrap */
/* global Shortcuts */

import findAndFollowLink from './shortcuts_dashboard_navigation';
import './shortcuts';

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsNavigation = (function(superClass) {
    extend(ShortcutsNavigation, superClass);

    function ShortcutsNavigation() {
      ShortcutsNavigation.__super__.constructor.call(this);
      Mousetrap.bind('g p', () => findAndFollowLink('.shortcuts-project'));
      Mousetrap.bind('g e', () => findAndFollowLink('.shortcuts-project-activity'));
      Mousetrap.bind('g f', () => findAndFollowLink('.shortcuts-tree'));
      Mousetrap.bind('g c', () => findAndFollowLink('.shortcuts-commits'));
      Mousetrap.bind('g j', () => findAndFollowLink('.shortcuts-builds'));
      Mousetrap.bind('g n', () => findAndFollowLink('.shortcuts-network'));
      Mousetrap.bind('g d', () => findAndFollowLink('.shortcuts-repository-charts'));
      Mousetrap.bind('g i', () => findAndFollowLink('.shortcuts-issues'));
      Mousetrap.bind('g b', () => findAndFollowLink('.shortcuts-issue-boards'));
      Mousetrap.bind('g m', () => findAndFollowLink('.shortcuts-merge_requests'));
      Mousetrap.bind('g t', () => findAndFollowLink('.shortcuts-todos'));
      Mousetrap.bind('g w', () => findAndFollowLink('.shortcuts-wiki'));
      Mousetrap.bind('g s', () => findAndFollowLink('.shortcuts-snippets'));
      Mousetrap.bind('i', () => findAndFollowLink('.shortcuts-new-issue'));
      this.enabledHelp.push('.hidden-shortcut.project');
    }

    return ShortcutsNavigation;
  })(Shortcuts);
}).call(window);

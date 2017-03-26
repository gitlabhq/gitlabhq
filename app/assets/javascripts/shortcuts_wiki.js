/* eslint-disable func-names, space-before-function-paren, max-len, no-var, one-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, one-var-declaration-per-line, quotes, prefer-arrow-callback, consistent-return, prefer-template, no-mixed-operators */
/* global Mousetrap */
/* global ShortcutsNavigation */

require('mousetrap');
require('./shortcuts_navigation');

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsWiki = (function(superClass) {
    extend(ShortcutsWiki, superClass);

    function ShortcutsWiki() {
      ShortcutsWiki.__super__.constructor.call(this);
      Mousetrap.bind('e', (function(_this) {
        return function() {
          _this.editWiki();
          return false;
        };
      })(this));
    }

    ShortcutsWiki.prototype.editWiki = function() {
      var $editBtn;
      $editBtn = $('.wiki-edit');
      return gl.utils.visitUrl($editBtn.attr('href'));
    };
    return ShortcutsWiki;
  })(ShortcutsNavigation);
}).call(window);

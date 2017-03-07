/* eslint-disable func-names, space-before-function-paren, max-len, no-var, one-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, one-var-declaration-per-line, quotes, prefer-arrow-callback, consistent-return, prefer-template, no-mixed-operators */
/* global Mousetrap */
/* global ShortcutsNavigation */
/* global sidebar */

require('mousetrap');
require('./shortcuts_navigation');

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsIssuable = (function(superClass) {
    extend(ShortcutsIssuable, superClass);

    function ShortcutsIssuable(isMergeRequest) {
      ShortcutsIssuable.__super__.constructor.call(this);
      Mousetrap.bind('a', this.openSidebarDropdown.bind(this, 'assignee'));
      Mousetrap.bind('m', this.openSidebarDropdown.bind(this, 'milestone'));
      Mousetrap.bind('r', (function(_this) {
        return function() {
          _this.replyWithSelectedText();
          return false;
        };
      })(this));
      Mousetrap.bind('e', (function(_this) {
        return function() {
          _this.editIssue();
          return false;
        };
      })(this));
      Mousetrap.bind('l', this.openSidebarDropdown.bind(this, 'labels'));
      if (isMergeRequest) {
        this.enabledHelp.push('.hidden-shortcut.merge_requests');
      } else {
        this.enabledHelp.push('.hidden-shortcut.issues');
      }
    }

    ShortcutsIssuable.prototype.replyWithSelectedText = function() {
      var quote, documentFragment, selected, separator;
      var replyField = $('.js-main-target-form #note_note');

      documentFragment = window.gl.utils.getSelectedFragment();
      if (!documentFragment) {
        replyField.focus();
        return;
      }

      // If the documentFragment contains more than just Markdown, don't copy as GFM.
      if (documentFragment.querySelector('.md, .wiki')) return;

      selected = window.gl.CopyAsGFM.nodeToGFM(documentFragment);

      if (selected.trim() === "") {
        return;
      }
      quote = _.map(selected.split("\n"), function(val) {
        return ("> " + val).trim() + "\n";
      });
      // If replyField already has some content, add a newline before our quote
      separator = replyField.val().trim() !== "" && "\n\n" || '';
      replyField.val(function(_, current) {
        return current + separator + quote.join('') + "\n";
      });

      // Trigger autosave
      replyField.trigger('input');

      // Trigger autosize
      var event = document.createEvent('Event');
      event.initEvent('autosize:update', true, false);
      replyField.get(0).dispatchEvent(event);

      // Focus the input field
      return replyField.focus();
    };

    ShortcutsIssuable.prototype.editIssue = function() {
      var $editBtn;
      $editBtn = $('.issuable-edit');
      return gl.utils.visitUrl($editBtn.attr('href'));
    };

    ShortcutsIssuable.prototype.openSidebarDropdown = function(name) {
      sidebar.openDropdown(name);
      return false;
    };

    return ShortcutsIssuable;
  })(ShortcutsNavigation);
}).call(window);

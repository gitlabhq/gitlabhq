/* eslint-disable func-names, space-before-function-paren, max-len, one-var, no-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, consistent-return, padded-blocks, no-undef, max-len */

/*= require shortcuts */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsBlob = (function(superClass) {
    extend(ShortcutsBlob, superClass);

    function ShortcutsBlob(skipResetBindings) {
      ShortcutsBlob.__super__.constructor.call(this, skipResetBindings);
      Mousetrap.bind('y', ShortcutsBlob.copyToClipboard);
    }

    ShortcutsBlob.copyToClipboard = function() {
      var clipboardButton;
      clipboardButton = $('.btn-clipboard');
      if (clipboardButton) {
        return clipboardButton.click();
      }
    };

    return ShortcutsBlob;

  })(Shortcuts);

}).call(this);

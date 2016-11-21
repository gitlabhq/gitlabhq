/* eslint-disable func-names, space-before-function-paren, max-len, one-var, no-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, padded-blocks, no-undef, max-len */

/*= require shortcuts_navigation */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsFindFile = (function(superClass) {
    extend(ShortcutsFindFile, superClass);

    function ShortcutsFindFile(projectFindFile) {
      var _oldStopCallback;
      this.projectFindFile = projectFindFile;
      ShortcutsFindFile.__super__.constructor.call(this);
      _oldStopCallback = Mousetrap.stopCallback;
      Mousetrap.stopCallback = (function(_this) {
        // override to fire shortcuts action when focus in textbox
        return function(event, element, combo) {
          if (element === _this.projectFindFile.inputElement[0] && (combo === 'up' || combo === 'down' || combo === 'esc' || combo === 'enter')) {
            // when press up/down key in textbox, cusor prevent to move to home/end
            event.preventDefault();
            return false;
          }
          return _oldStopCallback(event, element, combo);
        };
      })(this);
      Mousetrap.bind('up', this.projectFindFile.selectRowUp);
      Mousetrap.bind('down', this.projectFindFile.selectRowDown);
      Mousetrap.bind('esc', this.projectFindFile.goToTree);
      Mousetrap.bind('enter', this.projectFindFile.goToBlob);
    }

    return ShortcutsFindFile;

  })(ShortcutsNavigation);

}).call(this);

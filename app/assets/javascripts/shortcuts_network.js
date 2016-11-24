/* eslint-disable func-names, space-before-function-paren, max-len, no-var, one-var, no-restricted-syntax, vars-on-top, no-use-before-define, no-param-reassign, new-cap, no-underscore-dangle, wrap-iife, padded-blocks, no-undef, max-len */

/*= require shortcuts_navigation */

(function() {
  var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  this.ShortcutsNetwork = (function(superClass) {
    extend(ShortcutsNetwork, superClass);

    function ShortcutsNetwork(graph) {
      this.graph = graph;
      ShortcutsNetwork.__super__.constructor.call(this);
      Mousetrap.bind(['left', 'h'], this.graph.scrollLeft);
      Mousetrap.bind(['right', 'l'], this.graph.scrollRight);
      Mousetrap.bind(['up', 'k'], this.graph.scrollUp);
      Mousetrap.bind(['down', 'j'], this.graph.scrollDown);
      Mousetrap.bind(['shift+up', 'shift+k'], this.graph.scrollTop);
      Mousetrap.bind(['shift+down', 'shift+j'], this.graph.scrollBottom);
      this.enabledHelp.push('.hidden-shortcut.network');
    }

    return ShortcutsNetwork;

  })(ShortcutsNavigation);

}).call(this);

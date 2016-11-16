/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-return-assign, padded-blocks, max-len */
(function() {
  this.StatGraph = (function() {
    function StatGraph() {}

    StatGraph.log = {};

    StatGraph.get_log = function() {
      return this.log;
    };

    StatGraph.set_log = function(data) {
      return this.log = data;
    };

    return StatGraph;

  })();

}).call(this);

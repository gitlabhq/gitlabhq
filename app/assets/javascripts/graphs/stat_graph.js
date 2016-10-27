/* eslint-disable */
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

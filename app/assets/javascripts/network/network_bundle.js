/* eslint-disable func-names, space-before-function-paren, prefer-arrow-callback, quotes, no-var, vars-on-top, camelcase, comma-dangle, consistent-return, max-len */
/* global Network */
/* global ShortcutsNetwork */

// require everything else in this directory
function requireAll(context) { return context.keys().map(context); }
requireAll(require.context('.', false, /^\.\/(?!network_bundle).*\.(js|es6)$/));

(function() {
  $(function() {
    if (!$(".network-graph").length) return;

    var network_graph;
    network_graph = new Network({
      url: $(".network-graph").attr('data-url'),
      commit_url: $(".network-graph").attr('data-commit-url'),
      ref: $(".network-graph").attr('data-ref'),
      commit_id: $(".network-graph").attr('data-commit-id')
    });
    return new ShortcutsNetwork(network_graph.branch_graph);
  });
}).call(window);

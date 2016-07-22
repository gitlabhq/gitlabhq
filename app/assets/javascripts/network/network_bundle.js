
/*= require_tree . */
$(function() {
  var network_graph;
  network_graph = new Network({
    url: $(".network-graph").attr('data-url'),
    commit_url: $(".network-graph").attr('data-commit-url'),
    ref: $(".network-graph").attr('data-ref'),
    commit_id: $(".network-graph").attr('data-commit-id')
  });
  return new ShortcutsNetwork(network_graph.branch_graph);
});

# This is a manifest file that'll be compiled into including all the files listed below.
# Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
# be included in the compiled file accessible from http://example.com/assets/application.js
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
#= require_tree .

$ ->
  network_graph = new Network({
    url: $(".network-graph").attr('data-url'),
    commit_url: $(".network-graph").attr('data-commit-url'),
    ref: $(".network-graph").attr('data-ref'),
    commit_id: $(".network-graph").attr('data-commit-id')
  })

  new ShortcutsNetwork(network_graph.branch_graph)

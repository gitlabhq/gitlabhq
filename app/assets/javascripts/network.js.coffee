class @Network
  constructor: (opts) ->
    $("#filter_ref").click ->
      $(this).closest('form').submit()

    @branch_graph = new BranchGraph($(".network-graph"), opts)

    vph = $(window).height() - 250
    $('.network-graph').css 'height': (vph + 'px')

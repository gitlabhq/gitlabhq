function toggleGraph() {
  $('.pipeline-graph, .toggle-pipeline-btn').toggleClass('graph-collapsed');

  const $btnText = $('.toggle-pipeline-btn .btn-text');
  const graphCollapsed = $('.pipeline-graph').hasClass('graph-collapsed');

  graphCollapsed ? $btnText.text('Expand') : $btnText.text('Hide')
}

$(document).on('click', '.toggle-pipeline-btn', toggleGraph);

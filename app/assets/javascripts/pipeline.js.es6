function toggleGraph() {
  const indexOfBtn = $('.toggle-pipeline-btn').index($(this));

  $($('.pipeline-graph')[indexOfBtn]).toggleClass('graph-collapsed');
  $($('.toggle-pipeline-btn')[indexOfBtn]).toggleClass('graph-collapsed');

  const $btnText = $($('.toggle-pipeline-btn .btn-text')[indexOfBtn]);
  const graphCollapsed = $($('.pipeline-graph')[indexOfBtn]).hasClass('graph-collapsed');

  graphCollapsed ? $btnText.text('Expand') : $btnText.text('Hide')
}

$(document).on('click', '.toggle-pipeline-btn', toggleGraph);

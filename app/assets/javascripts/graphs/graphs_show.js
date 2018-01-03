import ContributorsStatGraph from './stat_graph_contributors';

document.addEventListener('DOMContentLoaded', () => {
  $.ajax({
    type: 'GET',
    url: document.querySelector('.js-graphs-show').dataset.projectGraphPath,
    dataType: 'json',
    success(data) {
      const graph = new ContributorsStatGraph();
      graph.init(data);

      $('#brush_change').change(() => {
        graph.change_date_header();
        graph.redraw_authors();
      });

      $('.stat-graph').fadeIn();
      $('.loading-graph').hide();
    },
  });
});

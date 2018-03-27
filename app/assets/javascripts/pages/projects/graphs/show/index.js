import $ from 'jquery';
import flash from '~/flash';
import { __ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import ContributorsStatGraph from './stat_graph_contributors';

document.addEventListener('DOMContentLoaded', () => {
  const url = document.querySelector('.js-graphs-show').dataset.projectGraphPath;

  axios.get(url)
    .then(({ data }) => {
      const graph = new ContributorsStatGraph();
      graph.init(data);

      $('#brush_change').change(() => {
        graph.change_date_header();
        graph.redraw_authors();
      });

      $('.stat-graph').fadeIn();
      $('.loading-graph').hide();
    })
    .catch(() => flash(__('Error fetching contributors data.')));
});

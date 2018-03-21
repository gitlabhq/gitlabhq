import $ from 'jquery';
import ShortcutsNetwork from '../../../../shortcuts_network';
import Network from '../network';

document.addEventListener('DOMContentLoaded', () => {
  if (!$('.network-graph').length) return;

  const networkGraph = new Network({
    url: $('.network-graph').attr('data-url'),
    commit_url: $('.network-graph').attr('data-commit-url'),
    ref: $('.network-graph').attr('data-ref'),
    commit_id: $('.network-graph').attr('data-commit-id'),
  });

  // eslint-disable-next-line no-new
  new ShortcutsNetwork(networkGraph.branch_graph);
});

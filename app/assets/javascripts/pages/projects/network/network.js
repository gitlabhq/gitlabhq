import $ from 'jquery';
import BranchGraph from '~/network/branch_graph';

const vph = $(window).height() - $('.project-network-header').height();

export default class Network {
  constructor(opts) {
    this.opts = opts;
    this.filter_ref = $('#filter_ref');
    this.network_graph = $('.network-graph');
    this.filter_ref.click(() => this.submit());
    this.branch_graph = new BranchGraph(this.network_graph, this.opts);
    this.network_graph.css({ height: `${vph}px` });
    $('body').css({ 'overflow-y': 'hidden' });
    $('.content-wrapper').css({ 'padding-bottom': 0 });
  }

  submit() {
    return this.filter_ref.closest('form').submit();
  }
}

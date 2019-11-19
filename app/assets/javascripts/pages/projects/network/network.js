import $ from 'jquery';
import BranchGraph from '../../../network/branch_graph';

const vph = $(window).height() - 250;

export default class Network {
  constructor(opts) {
    this.opts = opts;
    this.filter_ref = $('#filter_ref');
    this.network_graph = $('.network-graph');
    this.filter_ref.click(() => this.submit());
    this.branch_graph = new BranchGraph(this.network_graph, this.opts);
    this.network_graph.css({ height: `${vph}px` });
  }

  submit() {
    return this.filter_ref.closest('form').submit();
  }
}

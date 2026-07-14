import $ from 'jquery';
import { debounce } from 'lodash-es';
import BranchGraph from '~/network/branch_graph';

export default class Network {
  constructor(opts) {
    this.opts = opts;
    this.filter_ref = $('#filter_ref');
    this.network_graph = $('.network-graph');
    this.network_graph.css({ height: `${this.calculateHeight()}px` });
    this.filter_ref.click(() => this.submit());
    this.branch_graph = new BranchGraph(this.network_graph, this.opts);
    this.resetBodyStyles();
    this.resizeHandler = debounce(() => this.handleResize(), 100);
    window.addEventListener('resize', this.resizeHandler);
  }

  // eslint-disable-next-line class-methods-use-this
  calculateHeight() {
    const graph = document.querySelector('.network-graph');
    return window.innerHeight - graph.getBoundingClientRect().top;
  }

  handleResize() {
    this.network_graph.css({ height: `${this.calculateHeight()}px` });
  }

  // eslint-disable-next-line class-methods-use-this
  resetBodyStyles() {
    $('body').css({ 'overflow-y': 'hidden' });
    $('.content-wrapper').css({ 'padding-bottom': 0 });
    $('.panel-content-inner').css({ 'overflow-y': 'hidden' });
  }

  submit() {
    return this.filter_ref.closest('form').submit();
  }

  destroy() {
    if (this.branch_graph) {
      this.branch_graph.destroy();
      this.resetBodyStyles();
    }
    $('.panel-content-inner').css({
      'overflow-y': '',
      'overflow-x': 'auto',
    });
    window.removeEventListener('resize', this.resizeHandler);
  }
}

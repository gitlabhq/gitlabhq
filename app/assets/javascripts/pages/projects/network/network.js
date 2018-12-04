/* eslint-disable func-names, no-var, prefer-template */

import $ from 'jquery';
import BranchGraph from '../../../network/branch_graph';

export default (function() {
  function Network(opts) {
    var vph;
    $('#filter_ref').click(function() {
      return $(this)
        .closest('form')
        .submit();
    });
    this.branch_graph = new BranchGraph($('.network-graph'), opts);
    vph = $(window).height() - 250;
    $('.network-graph').css({
      height: vph + 'px',
    });
  }

  return Network;
})();

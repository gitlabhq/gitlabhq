import $ from 'jquery';
import stickyMonitor from './lib/utils/sticky';

export default (stickyTop) => {
  stickyMonitor(document.querySelector('.js-diff-files-changed'), stickyTop);

  $('.js-diff-stats-dropdown').glDropdown({
    filterable: true,
    remoteFilter: false,
  });
};

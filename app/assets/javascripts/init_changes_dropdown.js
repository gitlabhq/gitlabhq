import stickyMonitor from './lib/utils/sticky';

export default () => {
  stickyMonitor(document.querySelector('.js-diff-files-changed'), 76);

  $('.js-diff-stats-dropdown').glDropdown({
    filterable: true,
    remoteFilter: false,
  });
};

import stickyMonitor from './lib/utils/sticky';

export default () => {
  stickyMonitor(document.querySelector('.js-diff-files-changed'));

  $('.js-diff-stats-dropdown').glDropdown({
    filterable: true,
    remoteFilter: false,
  });
};

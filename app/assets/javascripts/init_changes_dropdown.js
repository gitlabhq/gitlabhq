import $ from 'jquery';
import StickyFill from 'stickyfilljs';

export default () => {
  StickyFill.add(document.querySelector('.js-diff-files-changed'));

  $('.js-diff-stats-dropdown').glDropdown({
    filterable: true,
    remoteFilter: false,
  });
};

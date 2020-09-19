import $ from 'jquery';
import { stickyMonitor } from './lib/utils/sticky';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default stickyTop => {
  stickyMonitor(document.querySelector('.js-diff-files-changed'), stickyTop);

  initDeprecatedJQueryDropdown($('.js-diff-stats-dropdown'), {
    filterable: true,
    remoteFilter: false,
  });
};

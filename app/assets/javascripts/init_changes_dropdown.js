import $ from 'jquery';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { stickyMonitor } from './lib/utils/sticky';

export default (stickyTop) => {
  stickyMonitor(document.querySelector('.js-diff-files-changed'), stickyTop);

  initDeprecatedJQueryDropdown($('.js-diff-stats-dropdown'), {
    filterable: true,
    remoteFilter: false,
  });
};

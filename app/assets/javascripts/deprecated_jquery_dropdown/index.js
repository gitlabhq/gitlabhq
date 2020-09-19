import $ from 'jquery';
import { GitLabDropdown } from './gl_dropdown';

export default function initDeprecatedJQueryDropdown($el, opts) {
  // eslint-disable-next-line func-names
  return $el.each(function() {
    if (!$.data(this, 'deprecatedJQueryDropdown')) {
      $.data(this, 'deprecatedJQueryDropdown', new GitLabDropdown(this, opts));
    }
  });
}

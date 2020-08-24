import $ from 'jquery';
import { __ } from './locale';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';

export default function issueStatusSelect() {
  $('.js-issue-status').each((i, el) => {
    const fieldName = $(el).data('fieldName');
    initDeprecatedJQueryDropdown($(el), {
      selectable: true,
      fieldName,
      toggleLabel(selected, element, instance) {
        let label = __('Author');
        const $item = instance.dropdown.find('.is-active');
        if ($item.length) {
          label = $item.text();
        }
        return label;
      },
      clicked(options) {
        return options.e.preventDefault();
      },
      id(obj, element) {
        return $(element).data('id');
      },
    });
  });
}

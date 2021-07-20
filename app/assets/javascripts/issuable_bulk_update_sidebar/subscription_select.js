import $ from 'jquery';
import initDeprecatedJQueryDropdown from '~/deprecated_jquery_dropdown';
import { __ } from '~/locale';

export default function subscriptionSelect() {
  $('.js-subscription-event').each((i, element) => {
    const fieldName = $(element).data('fieldName');

    return initDeprecatedJQueryDropdown($(element), {
      selectable: true,
      fieldName,
      toggleLabel(selected, el, instance) {
        let label = __('Subscription');
        const $item = instance.dropdown.find('.is-active');
        if ($item.length) {
          label = $item.text();
        }
        return label;
      },
      clicked(options) {
        return options.e.preventDefault();
      },
      id(obj, el) {
        return $(el).data('id');
      },
    });
  });
}

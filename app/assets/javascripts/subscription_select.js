import $ from 'jquery';

export default function subscriptionSelect() {
  $('.js-subscription-event').each((i, element) => {
    const fieldName = $(element).data('fieldName');

    return $(element).glDropdown({
      selectable: true,
      fieldName,
      toggleLabel(selected, el, instance) {
        let label = 'Subscription';
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

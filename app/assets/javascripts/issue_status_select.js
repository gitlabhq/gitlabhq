/* eslint-disable func-names,wrap-iife, no-shadow, no-unused-vars, one-var */
export default function issueStatusSelect() {
  $('.js-issue-status').each(function (i, el) {
    const fieldName = $(el).data('field-name');
    return $(el).glDropdown({
      selectable: true,
      fieldName,
      toggleLabel: (function (_this) {
        return function (selected, el, instance) {
          let label = 'Author';
          const $item = instance.dropdown.find('.is-active');
          if ($item.length) {
            label = $item.text();
          }
          return label;
        };
      })(this),
      clicked(options) {
        return options.e.preventDefault();
      },
      id(obj, el) {
        return $(el).data('id');
      },
    });
  });
}

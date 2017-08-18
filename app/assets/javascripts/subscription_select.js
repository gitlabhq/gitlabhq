/* eslint-disable func-names, space-before-function-paren, wrap-iife, no-var, quotes, object-shorthand, no-unused-vars, no-shadow, one-var, one-var-declaration-per-line, comma-dangle, max-len */

class SubscriptionSelect {
  constructor() {
    $('.js-subscription-event').each(function(i, el) {
      var fieldName;
      fieldName = $(el).data("field-name");
      return $(el).glDropdown({
        selectable: true,
        fieldName: fieldName,
        toggleLabel: (function(_this) {
          return function(selected, el, instance) {
            var $item, label;
            label = 'Subscription';
            $item = instance.dropdown.find('.is-active');
            if ($item.length) {
              label = $item.text();
            }
            return label;
          };
        })(this),
        clicked: function(options) {
          return options.e.preventDefault();
        },
        id: function(obj, el) {
          return $(el).data("id");
        }
      });
    });
  }
}

window.SubscriptionSelect = SubscriptionSelect;

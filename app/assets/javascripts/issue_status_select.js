this.IssueStatusSelect = (function() {
  function IssueStatusSelect() {
    $('.js-issue-status').each(function(i, el) {
      var fieldName;
      fieldName = $(el).data("field-name");
      return $(el).glDropdown({
        selectable: true,
        fieldName: fieldName,
        toggleLabel: (function(_this) {
          return function(selected, el, instance) {
            var $item, label;
            label = 'Author';
            $item = instance.dropdown.find('.is-active');
            if ($item.length) {
              label = $item.text();
            }
            return label;
          };
        })(this),
        clicked: function(item, $el, e) {
          return e.preventDefault();
        },
        id: function(obj, el) {
          return $(el).data("id");
        }
      });
    });
  }

  return IssueStatusSelect;

})();

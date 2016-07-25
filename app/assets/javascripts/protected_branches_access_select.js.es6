class ProtectedBranchesAccessSelect {
  constructor(container, saveOnSelect) {
    this.container = container;
    this.saveOnSelect = saveOnSelect;

    this.container.find(".allowed-to-merge").each((i, element) => {
      var fieldName = $(element).data('field-name');
      return $(element).glDropdown({
        data: gon.merge_access_levels,
        selectable: true,
        fieldName: fieldName,
        clicked: _.chain(this.onSelect).partial(element).bind(this).value()
      });
    });


    this.container.find(".allowed-to-push").each((i, element) => {
      var fieldName = $(element).data('field-name');
      return $(element).glDropdown({
        data: gon.push_access_levels,
        selectable: true,
        fieldName: fieldName,
        clicked: _.chain(this.onSelect).partial(element).bind(this).value()
      });
    });
  }

  onSelect(dropdown, selected, element, e) {
    $(dropdown).find('.dropdown-toggle-text').text(selected.text);
    if (this.saveOnSelect) {
      return $.ajax({
        type: "POST",
        url: $(dropdown).data('url'),
        dataType: "json",
        data: {
          _method: 'PATCH',
          id: $(dropdown).data('id'),
          protected_branch: {
            ["" + ($(dropdown).data('type'))]: selected.id
          }
        },
        success: function() {
          var row;
          row = $(e.target);
          return row.closest('tr').effect('highlight');
        },
        error: function() {
          return new Flash("Failed to update branch!", "alert");
        }
      });
    }
  }
}

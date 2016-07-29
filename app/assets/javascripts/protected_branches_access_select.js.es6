class ProtectedBranchesAccessSelect {
  constructor(container, saveOnSelect, selectDefault) {
    this.container = container;
    this.saveOnSelect = saveOnSelect;

    this.container.find(".allowed-to-merge").each((i, element) => {
      var fieldName = $(element).data('field-name');
      var dropdown = $(element).glDropdown({
        data: gon.merge_access_levels,
        selectable: true,
        fieldName: fieldName,
        clicked: _.chain(this.onSelect).partial(element).bind(this).value()
      });

      if (selectDefault) {
        dropdown.data('glDropdown').selectRowAtIndex(document.createEvent("Event"), 0);
      }
    });


    this.container.find(".allowed-to-push").each((i, element) => {
      var fieldName = $(element).data('field-name');
      var dropdown = $(element).glDropdown({
        data: gon.push_access_levels,
        selectable: true,
        fieldName: fieldName,
        clicked: _.chain(this.onSelect).partial(element).bind(this).value()
      });

      if (selectDefault) {
        dropdown.data('glDropdown').selectRowAtIndex(document.createEvent("Event"), 0);
      }
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
            ["" + ($(dropdown).data('type')) + "_attributes"]: {
              "access_level": selected.id
            }
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

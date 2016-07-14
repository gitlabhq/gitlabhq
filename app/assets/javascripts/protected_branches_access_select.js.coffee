class @ProtectedBranchesAccessSelect
  constructor: (@container, @saveOnSelect) ->
    @container.find(".allowed-to-merge").each (i, element) =>
      fieldName = $(element).data('field-name')
      $(element).glDropdown
        data: gon.merge_access_levels
        selectable: true
        fieldName: fieldName
        clicked: _.partial(@onSelect, element)

    @container.find(".allowed-to-push").each (i, element) =>
      fieldName = $(element).data('field-name')
      $(element).glDropdown
        data: gon.push_access_levels
        selectable: true
        fieldName: fieldName
        clicked: _.partial(@onSelect, element)


  onSelect: (dropdown, selected, element, e) =>
    $(dropdown).find('.dropdown-toggle-text').text(selected.text)
    if @saveOnSelect
      $.ajax
        type: "PATCH"
        url: $(dropdown).data('url')
        dataType: "json"
        data:
          id: $(dropdown).data('id')
          protected_branch:
            "#{$(dropdown).data('type')}": selected.id

        success: ->
          row = $(e.target)
          row.closest('tr').effect('highlight')
          new Flash("Updated protected branch!", "notice")

        error: ->
          new Flash("Failed to update branch!", "alert")


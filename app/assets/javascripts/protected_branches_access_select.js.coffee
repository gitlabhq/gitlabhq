class @ProtectedBranchesAccessSelect
  constructor: () ->
    $(".allowed-to-merge").each (i, element) =>
      fieldName = $(element).data('field-name')
      $(element).glDropdown
        data: [{id: 'developers', text: 'Developers'}, {id: 'masters', text: 'Masters'}]
        selectable: true
        fieldName: fieldName
        clicked: _.partial(@onSelect, element)

    $(".allowed-to-push").each (i, element) =>
      fieldName = $(element).data('field-name')
      $(element).glDropdown
        data: [{id: 'no_one', text: 'No one'},
               {id: 'developers', text: 'Developers'},
               {id: 'masters', text: 'Masters'}]
        selectable: true
        fieldName: fieldName
        clicked: _.partial(@onSelect, element)


  onSelect: (dropdown, selected, element, e) =>
    $(dropdown).find('.dropdown-toggle-text').text(selected.text)
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

      error: ->
        new Flash("Failed to update branch!", "alert")


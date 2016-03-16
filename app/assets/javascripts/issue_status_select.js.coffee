class @IssueStatusSelect
  constructor: ->
    $('.js-issue-status').each (i, el) ->
      fieldName = $(el).data("field-name")

      $(el).glDropdown(
        selectable: true
        fieldName: fieldName
        id: (obj, el) ->
          $(el).data("id")
      )

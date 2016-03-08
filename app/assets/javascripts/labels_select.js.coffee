class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      selectedLabel = $(dropdown).data('selected')

      $(dropdown).glDropdown(
        data: (callback) ->
          Api.projectLabels 8, callback
        renderRow: (label) ->
          selected = if label.name is selectedLabel then "is-active" else ""

          "<li>
            <a href='#' class='#{selected}'>
              #{label.name}
            </a>
          </li>"
        filterable: true
        search:
          fields: ['name']
        selectable: true
        fieldName: $(dropdown).data('field-name')
        id: (label) ->
          label.name
        clicked: ->
          $(dropdown).parents('form').submit()
      )

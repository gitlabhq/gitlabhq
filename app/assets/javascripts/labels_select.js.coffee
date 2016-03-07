class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')

      $(dropdown).glDropdown(
        data: (callback) ->
          Api.projectLabels 8, callback
        renderRow: (label) ->
          "<li>
            <a href='#'>
              <span class='label' style='background-color: #{label.color}'>#{label.name}</span>
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

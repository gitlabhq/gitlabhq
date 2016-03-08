class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      selectedLabel = $(dropdown).data('selected')
      newLabelField = $('#new_label_name')
      newColorField = $('#new_label_color')

      if newLabelField.length
        $('.suggest-colors-dropdown a').on "click", (e) ->
          e.preventDefault()
          e.stopPropagation()
          newColorField.val $(this).data("color")
          $('.js-dropdown-label-color-preview')
            .css 'background-color', $(this).data("color")
            .addClass 'is-active'

        $('.js-new-label-btn').on "click", (e) ->
          e.preventDefault()
          e.stopPropagation()

          if newLabelField.val() isnt "" && newColorField.val() isnt ""
            $('.js-new-label-btn').disable()

            # Create new label with API
            Api.newLabel projectId, {
              name: newLabelField.val()
              color: newColorField.val()
            }, (label) ->
              $('.js-new-label-btn').enable()
              $('.dropdown-menu-back', $(dropdown).parent()).trigger "click"

      $(dropdown).glDropdown(
        data: (term, callback) ->
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
          if $(dropdown).hasClass "js-filter-submit"
            $(dropdown).parents('form').submit()
      )

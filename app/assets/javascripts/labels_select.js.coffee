class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      labelUrl = $(dropdown).data("labels")
      selectedLabel = $(dropdown).data('selected')
      if selectedLabel
        selectedLabel = selectedLabel.toString().split(",")
      newLabelField = $('#new_label_name')
      newColorField = $('#new_label_color')
      showNo = $(dropdown).data('show-no')
      showAny = $(dropdown).data('show-any')

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
              $('.dropdown-menu-back', $(dropdown).parents('.dropdown')).trigger "click"

      $(dropdown).glDropdown(
        data: (term, callback) ->
          # We have to fetch the JS version of the labels list because there is no
          # public facing JSON url for labels
          $.ajax(
            url: labelUrl
          ).always (labels) ->
            data = []
            if $(dropdown).hasClass "js-sidebar-label-select"
              $.each labels, (i, label) ->
                data.push(
                  id: label.id
                  color: label.color
                  title: label.title
                )
            else
              html = $(labels.responseText)
              html.find('.label-row a').each ->
                data.push(
                  title: $(@).text().trim()
                )

            if showNo
              data.unshift(
                id: "0"
                title: 'No label'
              )

            if showAny
              data.unshift(
                title: 'Any label'
              )

            if data.length > 2 && (showNo or showAny)
              data.splice 2, 0, "divider"

            callback data
        renderRow: (label) ->
          if $.isArray(selectedLabel)
            selected = ""
            $.each selectedLabel, (i, selectedLbl) ->
              selectedLbl = selectedLbl.trim()
              labelToCompare = if label.id then label.id.toString() else label.title

              if selected is "" && labelToCompare is selectedLbl
                selected = "is-active"
          else
            selected = if label.title is selectedLabel then "is-active" else ""

          "<li>
            <a href='#' class='#{selected}'>
              #{label.title}
            </a>
          </li>"
        filterable: true
        search:
          fields: ['title']
        selectable: true
        multiSelect: $(dropdown).data('multi-select')
        fieldName: $(dropdown).data('field-name')
        id: (label) ->
          if label.id
            label.id
          else
            label.title
        clicked: ->
          if $(dropdown).hasClass "js-filter-submit"
            $(dropdown).parents('form').submit()
      )

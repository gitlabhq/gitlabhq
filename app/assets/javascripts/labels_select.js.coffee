class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      projectId = $(dropdown).data('project-id')
      labelUrl = $(dropdown).data("labels")
      selectedLabel = $(dropdown).data('selected')
      if selectedLabel
        selectedLabel = selectedLabel.split(",")
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
              $('.dropdown-menu-back', $(dropdown).parent()).trigger "click"

      $(dropdown).glDropdown(
        data: (term, callback) ->
          # We have to fetch the JS version of the labels list because there is no
          # public facing JSON url for labels
          $.ajax(
            url: labelUrl
          ).done (data) ->
            html = $(data)
            data = []
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

            if data.length > 2
              data.splice 2, 0, "divider"

            callback data
        renderRow: (label) ->
          if $.isArray(selectedLabel)
            selected = ""
            $.each selectedLabel, (i, selectedLbl) ->
              selectedLbl = selectedLbl.trim()
              if selected is "" && label.title is selectedLbl
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
        fieldName: $(dropdown).data('field-name')
        id: (label) ->
          label.title
        clicked: ->
          if $(dropdown).hasClass "js-filter-submit"
            $(dropdown).parents('form').submit()
      )

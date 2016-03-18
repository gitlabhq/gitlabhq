class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      projectId = $dropdown.data('project-id')
      labelUrl = $dropdown.data('labels')
      selectedLabel = $dropdown.data('selected')
      if selectedLabel
        selectedLabel = selectedLabel.split(',')
      newLabelField = $('#new_label_name')
      newColorField = $('#new_label_color')
      showNo = $dropdown.data('show-no')
      showAny = $dropdown.data('show-any')
      defaultLabel = $dropdown.data('default-label')

      if newLabelField.length
        $('.suggest-colors-dropdown a').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          newColorField.val $(this).data('color')
          $('.js-dropdown-label-color-preview')
            .css 'background-color', $(this).data('color')
            .addClass 'is-active'

        $('.js-new-label-btn').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()

          if newLabelField.val() isnt '' and newColorField.val() isnt ''
            $('.js-new-label-btn').disable()

            # Create new label with API
            Api.newLabel projectId, {
              name: newLabelField.val()
              color: newColorField.val()
            }, (label) ->
              $('.js-new-label-btn').enable()
              $('.dropdown-menu-back', $dropdown.parent()).trigger 'click'

      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: labelUrl
          ).done (data) ->
            if showNo
              data.unshift(
                id: 0
                title: 'No Label'
              )

            if showAny
              data.unshift(
                isAny: true
                title: 'Any Label'
              )

            if data.length > 2
              data.splice 2, 0, 'divider'

            callback data
        renderRow: (label) ->
          if $.isArray(selectedLabel)
            selected = ''
            $.each selectedLabel, (i, selectedLbl) ->
              selectedLbl = selectedLbl.trim()
              if selected is '' and label.title is selectedLbl
                selected = 'is-active'
          else
            selected = if label.title is selectedLabel then 'is-active' else ''

          "<li>
            <a href='#' class='#{selected}'>
              #{label.title}
            </a>
          </li>"
        filterable: true
        search:
          fields: ['title']
        selectable: true
        toggleLabel: (selected) ->
          if selected and selected.title isnt 'Any Label'
            selected.title
          else
            defaultLabel
        fieldName: $dropdown.data('field-name')
        id: (label) ->
          if label.isAny?
            ''
          else
            label.title
        clicked: ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is page is 'projects:merge_requests:index'

          if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
            Issues.filterResults $dropdown.closest('form')
          else if $dropdown.hasClass 'js-filter-submit'
            $dropdown.closest('form').submit()
      )

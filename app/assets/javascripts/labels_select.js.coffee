class @LabelsSelect
  constructor: ->
    $('.js-label-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      projectId = $dropdown.data('project-id')
      labelUrl = $dropdown.data('labels')
      issueUpdateURL = $dropdown.data('issueUpdate')
      selectedLabel = $dropdown.data('selected')
      if selectedLabel? and not $dropdown.hasClass 'js-multiselect'
        selectedLabel = selectedLabel.split(',')
      newLabelField = $('#new_label_name')
      newColorField = $('#new_label_color')
      showNo = $dropdown.data('show-no')
      showAny = $dropdown.data('show-any')
      defaultLabel = $dropdown.data('default-label')
      abilityName = $dropdown.data('ability-name')
      $selectbox = $dropdown.closest('.selectbox')
      $block = $selectbox.closest('.block')
      $form = $dropdown.closest('form')
      $sidebarCollapsedValue = $block.find('.sidebar-collapsed-icon span')
      $value = $block.find('.value')
      $newLabelError = $('.js-label-error')
      $colorPreview = $('.js-dropdown-label-color-preview')
      $newLabelCreateButton = $('.js-new-label-btn')

      $newLabelError.hide()
      $loading = $block.find('.block-loading').fadeOut()

      issueURLSplit = issueUpdateURL.split('/') if issueUpdateURL?
      if issueUpdateURL
        labelHTMLTemplate = _.template(
            '<% _.each(labels, function(label){ %>
            <a href="<%= ["",issueURLSplit[1], issueURLSplit[2],""].join("/") %>issues?label_name=<%= _.escape(label.title) %>">
            <span class="label has-tooltip color-label" title="<%= _.escape(label.description) %>" style="background-color: <%= label.color %>;">
            <%= _.escape(label.title) %>
            </span>
            </a>
            <% }); %>'
        )
        labelNoneHTMLTemplate = _.template('<div class="light">None</div>')

      if newLabelField.length

        # Suggested colors in the dropdown to chose from pre-chosen colors
        $('.suggest-colors-dropdown a').on "click", (e) ->
          e.preventDefault()
          e.stopPropagation()
          newColorField
            .val($(this).data('color'))
            .trigger('change')
          $colorPreview
            .css 'background-color', $(this).data('color')
            .parent()
            .addClass 'is-active'

        # Cancel button takes back to first page
        resetForm = ->
          newLabelField
            .val ''
            .trigger 'change'
          newColorField
            .val ''
            .trigger 'change'
          $colorPreview
            .css 'background-color', ''
            .parent()
            .removeClass 'is-active'

        $('.dropdown-menu-back').on 'click', ->
          resetForm()

        $('.js-cancel-label-btn').on 'click', (e) ->
          e.preventDefault()
          e.stopPropagation()
          resetForm()
          $('.dropdown-menu-back', $dropdown.parent()).trigger 'click'

        # Listen for change and keyup events on label and color field
        # This allows us to enable the button when ready
        enableLabelCreateButton = ->
          if newLabelField.val() isnt '' and newColorField.val() isnt ''
            $newLabelError.hide()
            $newLabelCreateButton.enable()
          else
            $newLabelCreateButton.disable()

        saveLabel = ->
          # Create new label with API
          Api.newLabel projectId, {
            name: newLabelField.val()
            color: newColorField.val()
          }, (label) ->
            $newLabelCreateButton.enable()

            if label.message?
              $newLabelError
                .text label.message
                .show()
            else
              $('.dropdown-menu-back', $dropdown.parent()).trigger 'click'

        newLabelField.on 'keyup change', enableLabelCreateButton

        newColorField.on 'keyup change', enableLabelCreateButton

        # Send the API call to create the label
        $newLabelCreateButton
          .disable()
          .on 'click', (e) ->
            e.preventDefault()
            e.stopPropagation()
            saveLabel()

      saveLabelData = ->
        selected = $dropdown
          .closest('.selectbox')
          .find("input[name='#{$dropdown.data('field-name')}']")
          .map(->
            @value
          ).get()
        data = {}
        data[abilityName] = {}
        data[abilityName].label_ids = selected
        if not selected.length
          data[abilityName].label_ids = ['']
        $loading.fadeIn()
        $dropdown.trigger('loading.gl.dropdown')
        $.ajax(
          type: 'PUT'
          url: issueUpdateURL
          dataType: 'JSON'
          data: data
        ).done (data) ->
          $loading.fadeOut()
          $dropdown.trigger('loaded.gl.dropdown')
          $selectbox.hide()
          data.issueURLSplit = issueURLSplit
          labelCount = 0
          if data.labels.length
            template = labelHTMLTemplate(data)
            labelCount = data.labels.length
          else
            template = labelNoneHTMLTemplate()
          $value
            .removeAttr('style')
            .html(template)
          $sidebarCollapsedValue.text(labelCount)

          $('.has-tooltip', $value).tooltip(container: 'body')

          $value
            .find('a')
            .each((i) ->
              setTimeout(=>
                gl.animate.animate($(@), 'pulse')
              ,200 * i
              )
            )


      $dropdown.glDropdown(
        data: (term, callback) ->
          $.ajax(
            url: labelUrl
          ).done (data) ->
            if $dropdown.hasClass 'js-extra-options'
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
          removesAll = label.id is 0 or not label.id?

          selectedClass = []
          if $form.find("input[type='hidden']\
            [name='#{$dropdown.data('fieldName')}']\
            [value='#{this.id(label)}']").length
            selectedClass.push 'is-active'

          if $dropdown.hasClass('js-multiselect') and removesAll
            selectedClass.push 'dropdown-clear-active'

          color = if label.color? then "<span class='dropdown-label-box' style='background-color: #{label.color}'></span>" else ""

          "<li>
            <a href='#' class='#{selectedClass.join(' ')}'>
              #{color}
              #{_.escape(label.title)}
            </a>
          </li>"
        filterable: true
        search:
          fields: ['title']
        selectable: true

        toggleLabel: (selected, el) ->
          selected_labels = $('.js-label-select').siblings('.dropdown-menu-labels').find('.is-active')

          if selected and selected.title?
            if selected_labels.length > 1
              "#{selected.title} +#{selected_labels.length - 1} more"
            else
              selected.title
          else if not selected and selected_labels.length isnt 0
            if selected_labels.length > 1
              "#{$(selected_labels[0]).text()} +#{selected_labels.length - 1} more"
            else if selected_labels.length is 1
              $(selected_labels).text()
          else
            defaultLabel
        fieldName: $dropdown.data('field-name')
        id: (label) ->
          if $dropdown.hasClass("js-filter-submit") and not label.isAny?
            label.title
          else
            label.id

        hidden: ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is 'projects:merge_requests:index'

          $selectbox.hide()
          # display:block overrides the hide-collapse rule
          $value.removeAttr('style')
          if $dropdown.hasClass 'js-multiselect'
            if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
              selectedLabels = $dropdown
                .closest('form')
                .find("input:hidden[name='#{$dropdown.data('fieldName')}']")
              Issuable.filterResults $dropdown.closest('form')
            else if $dropdown.hasClass('js-filter-submit')
              $dropdown.closest('form').submit()
            else
              saveLabelData()

        multiSelect: $dropdown.hasClass 'js-multiselect'
        clicked: (label) ->
          page = $('body').data 'page'
          isIssueIndex = page is 'projects:issues:index'
          isMRIndex = page is 'projects:merge_requests:index'
          if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
            if not $dropdown.hasClass 'js-multiselect'
              selectedLabel = label.title
              Issuable.filterResults $dropdown.closest('form')
          else if $dropdown.hasClass 'js-filter-submit'
            $dropdown.closest('form').submit()
          else
            if $dropdown.hasClass 'js-multiselect'
              return
            else
              saveLabelData()
      )

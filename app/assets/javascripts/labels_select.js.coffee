class @LabelsSelect
  constructor: ->
    _this = @

    $('.js-label-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      $toggleText = $dropdown.find('.dropdown-toggle-text')
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
      fieldName = $dropdown.data('field-name')
      useId = $dropdown.hasClass('js-issuable-form-dropdown') or $dropdown.hasClass('js-filter-bulk-update')
      propertyName = if useId then "id" else "title"

      $newLabelError.hide()
      $loading = $block.find('.block-loading').fadeOut()

      issueURLSplit = issueUpdateURL.split('/') if issueUpdateURL?
      if issueUpdateURL
        labelHTMLTemplate = _.template(
            '<% _.each(labels, function(label){ %>
            <a href="<%- ["",issueURLSplit[1], issueURLSplit[2],""].join("/") %>issues?label_name[]=<%- encodeURIComponent(label.title) %>">
            <span class="label has-tooltip color-label" title="<%- label.description %>" style="background-color: <%- label.color %>; color: <%- label.text_color %>;">
            <%- label.title %>
            </span>
            </a>
            <% }); %>'
        )
        labelNoneHTMLTemplate = '<span class="no-value">None</span>'

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
              errors = _.map label.message, (value, key) ->
                "#{key} #{value[0]}"

              $newLabelError
                .html errors.join("<br/>")
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
          .find("input[name='#{fieldName}']")
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
            template = labelNoneHTMLTemplate
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
            data = _.chain data
              .groupBy (label) ->
                label.title
              .map (label) ->
                color = _.map label, (dup) ->
                  dup.color

                return {
                  id: label[0].id
                  title: label[0].title
                  color: color
                  duplicate: color.length > 1
                }
              .value()

            if $dropdown.hasClass 'js-extra-options'
              extraData = []
              if showAny
                extraData.push(
                  isAny: true
                  title: 'Any Label'
                )

              if showNo
                extraData.push(
                  id: 0
                  title: 'No Label'
                )

              if extraData.length
                extraData.push 'divider'
                data = extraData.concat(data)

            callback data

        renderRow: (label, instance) ->
          $li = $('<li>')
          $a  = $('<a href="#">')

          selectedClass = []
          removesAll = label.id is 0 or not label.id?

          if $dropdown.hasClass('js-filter-bulk-update')
            indeterminate = instance.indeterminateIds
            active = instance.activeIds

            if indeterminate.indexOf(label.id) isnt -1
              selectedClass.push 'is-indeterminate'

            if active.indexOf(label.id) isnt -1
              # Remove is-indeterminate class if the item will be marked as active
              i = selectedClass.indexOf 'is-indeterminate'
              selectedClass.splice i, 1 unless i is -1

              selectedClass.push 'is-active'

              # Add input manually
              instance.addInput @fieldName, label.id

          if $form.find("input[type='hidden']\
            [name='#{$dropdown.data('fieldName')}']\
            [value='#{this.id(label)}']").length
            selectedClass.push 'is-active'

          if $dropdown.hasClass('js-multiselect') and removesAll
            selectedClass.push 'dropdown-clear-active'

          if label.duplicate
            spacing = 100 / label.color.length

            # Reduce the colors to 4
            label.color = label.color.filter (color, i) ->
              i < 4

            color = _.map(label.color, (color, i) ->
              percentFirst = Math.floor(spacing * i)
              percentSecond = Math.floor(spacing * (i + 1))
              "#{color} #{percentFirst}%,#{color} #{percentSecond}% "
            ).join(',')
            color = "linear-gradient(#{color})"
          else
            if label.color?
              color = label.color[0]

          if color
            colorEl = "<span class='dropdown-label-box' style='background: #{color}'></span>"
          else
            colorEl = ''

          # We need to identify which items are actually labels
          if label.id
            selectedClass.push('label-item')
            $a.attr('data-label-id', label.id)

          $a.addClass(selectedClass.join(' '))
            .html("#{colorEl} #{label.title}")

          # Return generated html
          $li.html($a).prop('outerHTML')
        persistWhenHide: $dropdown.data('persistWhenHide')
        search:
          fields: ['title']
        selectable: true
        filterable: true
        toggleLabel: (selected, el, glDropdown) ->
          if glDropdown?
            selectedIds = $("input[name='#{fieldName}']").map(-> $(this).val()).get()

            selected = _.filter glDropdown.fullData, (label) ->
              selectedIds.indexOf("#{label[propertyName]}") >= 0 if label[propertyName]?

            if selected.length is 1
              selected[0].title
            else if selected.length > 1
              "#{selected[0].title} +#{selected.length - 1} more"
            else
              defaultLabel
        defaultLabel: defaultLabel
        fieldName: fieldName
        id: (label) ->
          if $dropdown.hasClass('js-issuable-form-dropdown')
            if label.id is 0
              return
            else
              return label.id

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

          return if $dropdown.hasClass('js-issuable-form-dropdown')

          if $dropdown.hasClass 'js-multiselect'
            if $dropdown.hasClass('js-filter-submit') and (isIssueIndex or isMRIndex)
              selectedLabels = $dropdown
                .closest('form')
                .find("input:hidden[name='#{$dropdown.data('fieldName')}']")
              Issuable.filterResults $dropdown.closest('form')
            else if $dropdown.hasClass('js-filter-submit')
              $dropdown.closest('form').submit()
            else
              if not $dropdown.hasClass 'js-filter-bulk-update'
                saveLabelData()

          if $dropdown.hasClass('js-filter-bulk-update')
            # If we are persisting state we need the classes
            if not @options.persistWhenHide
              $dropdown.parent().find('.is-active, .is-indeterminate').removeClass()

        multiSelect: $dropdown.hasClass 'js-multiselect'
        clicked: (label) ->
          _this.enableBulkLabelDropdown()

          if $dropdown.hasClass('js-filter-bulk-update') or $dropdown.hasClass('js-issuable-form-dropdown')
            return

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

        setIndeterminateIds: ->
          if @dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')
            @indeterminateIds = _this.getIndeterminateIds()

        setActiveIds: ->
          if @dropdown.find('.dropdown-menu-toggle').hasClass('js-filter-bulk-update')
            @activeIds = _this.getActiveIds()
      )

    @bindEvents()

  bindEvents: ->
    $('body').on 'change', '.selected_issue', @onSelectCheckboxIssue

  onSelectCheckboxIssue: ->
    return if $('.selected_issue:checked').length

    # Remove inputs
    $('.issues_bulk_update .labels-filter input[type="hidden"]').remove()

    # Also restore button text
    $('.issues_bulk_update .labels-filter .dropdown-toggle-text').text('Label')

  getIndeterminateIds: ->
    label_ids = []

    $('.selected_issue:checked').each (i, el) ->
      issue_id = $(el).data('id')
      label_ids.push $("#issue_#{issue_id}").data('labels')

    _.flatten(label_ids)

  getActiveIds: ->
    label_ids = []

    $('.selected_issue:checked').each (i, el) ->
      issue_id = $(el).data('id')
      label_ids.push $("#issue_#{issue_id}").data('labels')

    _.intersection.apply _, label_ids

  enableBulkLabelDropdown: ->
    if $('.selected_issue:checked').length
      issuableBulkActions = $('.bulk-update').data('bulkActions')
      issuableBulkActions.willUpdateLabels = true

class @DueDateSelect
  constructor: ->
    $loading = $('.js-issuable-update .due_date')
      .find('.block-loading')
      .hide()

    $('.js-due-date-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      $dropdownParent = $dropdown.closest('.dropdown')
      $datePicker = $dropdownParent.find('.js-due-date-calendar')
      $block = $dropdown.closest('.block')
      $selectbox = $dropdown.closest('.selectbox')
      $value = $block.find('.value')
      $sidebarValue = $('.js-due-date-sidebar-value', $block)

      fieldName = $dropdown.data('field-name')
      abilityName = $dropdown.data('ability-name')
      issueUpdateURL = $dropdown.data('issue-update')

      $dropdown.glDropdown(
        hidden: ->
          $selectbox.hide()
          $value.removeAttr('style')
      )

      addDueDate = ->
        # Create the post date
        value = $("input[name='#{fieldName}']").val()
        date = new Date value.replace(new RegExp('-', 'g'), ',')
        mediumDate = $.datepicker.formatDate 'M d, yy', date

        data = {}
        data[abilityName] = {}
        data[abilityName].due_date = value

        $.ajax(
          type: 'PUT'
          url: issueUpdateURL
          data: data
          beforeSend: ->
            $loading.fadeIn()
            $dropdown.trigger('loading.gl.dropdown')
            $selectbox.hide()
            $value.removeAttr('style')

            $value.html(mediumDate)
            $sidebarValue.html(mediumDate)
        ).done (data) ->
          $dropdown.trigger('loaded.gl.dropdown')
          $dropdown.dropdown('toggle')
          $loading.fadeOut()

      $datePicker.datepicker(
        dateFormat: 'yy-mm-dd',
        defaultDate: $("input[name='#{fieldName}']").val()
        altField: "input[name='#{fieldName}']"
        onSelect: ->
          addDueDate()
      )

    $(document)
      .off 'click', '.ui-datepicker-header a'
      .on 'click', '.ui-datepicker-header a', (e) ->
        e.stopImmediatePropagation()

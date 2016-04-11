class @DueDateSelect
  constructor: ->
    $loading = $('.js-issuable-update .due_date').find('.block-loading').hide()

    $('.js-due-date-select').each (i, dropdown) ->
      $dropdown = $(dropdown)
      $dropdownParent = $dropdown.closest('.dropdown')
      $addBtn = $('.js-due-date-add', $dropdownParent)
      $datePicker = $dropdownParent.find('.js-due-date-calendar')
      $block = $dropdown.closest('.block')
      $selectbox = $dropdown.closest('.selectbox')
      $value = $block.find('.value')

      fieldName = $dropdown.data('field-name')
      abilityName = $dropdown.data('ability-name')
      issueUpdateURL = $dropdown.data('issue-update')

      $dropdown.glDropdown(
        hidden: ->
          $selectbox.hide()
          $value.removeAttr('style')
      )

      $addBtn.on 'click', (e) ->
        e.preventDefault()
        e.stopPropagation()

        # Create the post date
        value = $("input[name='#{fieldName}']").val()
        mediumDate = $.datepicker.formatDate("M d, yy", new Date(value))

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
        ).done (data) ->
          $dropdown.trigger('loaded.gl.dropdown')
          $loading.fadeOut()

      $datePicker.datepicker(
        dateFormat: "yy-mm-dd",
        defaultDate: $("input[name='#{fieldName}']").val()
        altField: "input[name='#{fieldName}']"
      )

    $(document)
      .off 'click', '.ui-datepicker-header a'
      .on 'click', '.ui-datepicker-header a', (e) ->
        e.stopImmediatePropagation()

#= require jquery.waitforimages
#= require task_list

class @Issue
  constructor: ->
    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()
      @initIssueBtnEventListeners()

  initTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.detail-page-description .js-task-list-container', @updateTaskList

  initIssueBtnEventListeners: ->
    $("a.btn-close, a.btn-reopen").on "click", (e) ->
      e.preventDefault()
      e.stopImmediatePropagation()
      $this = $(this)
      isClose = $this.hasClass('btn-close')
      $this.prop("disabled", true)
      url = $this.attr('href')
      $.ajax
        type: 'PUT'
        url: url,
        error: (jqXHR, textStatus, errorThrown) ->
          issueStatus = if isClose then 'close' else 'open'
        success: (data, textStatus, jqXHR) ->
          if data.saved
            $this.addClass('hidden')
            if isClose
              $('a.btn-reopen').removeClass('hidden')
              $('div.issue-box-closed').removeClass('hidden')
              $('div.issue-box-open').addClass('hidden')
            else
              $('a.btn-close').removeClass('hidden')
              $('div.issue-box-closed').addClass('hidden')
              $('div.issue-box-open').removeClass('hidden')
          else
          $this.prop('disabled', false)

  disableTaskList: ->
    $('.detail-page-description .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.detail-page-description .js-task-list-container'

  # TODO (rspeicher): Make the issue description inline-editable like a note so
  # that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['issue'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData

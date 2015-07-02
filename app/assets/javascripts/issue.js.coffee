#= require jquery.waitforimages
#= require task_list

class @Issue
  constructor: ->
    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

  initTaskList: ->
    $('.issue-details .js-task-list-container').taskList('enable')
    $(document).on 'tasklist:changed', '.issue-details .js-task-list-container', @updateTaskList

  disableTaskList: ->
    $('.issue-details .js-task-list-container').taskList('disable')
    $(document).off 'tasklist:changed', '.issue-details .js-task-list-container'

  # TODO (rspeicher): Make the issue description inline-editable like a note so
  # that we can re-use its form here
  updateTaskList: ->
    patchData = {}
    patchData['issue'] = {'description': $('.js-task-list-field', this).val()}

    $.ajax
      type: 'PATCH'
      url: $('form.js-issuable-update').attr('action')
      data: patchData

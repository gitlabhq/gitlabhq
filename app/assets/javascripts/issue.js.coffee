#= require jquery
#= require jquery.waitforimages
#= require task_list

class @Issue
  constructor: ->
    $('.edit-issue.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#issue_assignee_id", ->
      $(this).submit()

    # Prevent duplicate event bindings
    @disableTaskList()

    if $("a.btn-close").length
      @initTaskList()

    $('.issue-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = ($('.issuable-affix').offset().top - 70)
        bottom: ->
          @bottom = $('.footer').outerHeight(true)
      $('.issuable-affix').on 'affix.bs.affix', ->
        $(@).width($(@).outerWidth())
      .on 'affixed-top.bs.affix affixed-bottom.bs.affix', ->
        $(@).width('')

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
      url: $('form.js-issue-update').attr('action')
      data: patchData

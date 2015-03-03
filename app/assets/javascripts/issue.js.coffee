class @Issue
  constructor: ->
    $('.edit-issue.inline-update input[type="submit"]').hide()
    $(".context .inline-update").on "change", "select", ->
      $(this).submit()
    $(".context .inline-update").on "change", "#issue_assignee_id", ->
      $(this).submit()

    if $("a.btn-close").length
      $("li.task-list-item input:checkbox").prop("disabled", false)

    $(".task-list-item input:checkbox").on(
      "click"
      null
      "issue"
      updateTaskState
    )

    $('.issue-details').waitForImages ->
      $('.issuable-affix').affix offset:
        top: ->
          @top = $('.issue-details').outerHeight(true) + 25
        bottom: ->
          @bottom = $('.footer').outerHeight(true)

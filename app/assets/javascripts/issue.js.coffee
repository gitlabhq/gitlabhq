class @Issue
  constructor: ->
    $('.edit-issue.inline-update input[type="submit"]').hide()
    $(".issue-box .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issue-box .inline-update").on "change", "#issue_assignee_id", ->
      $(this).submit()

    if $("a.btn-close").length
      $("li.task-list-item input:checkbox").prop("disabled", false)

    $(".task-list-item input:checkbox").on(
      "click"
      null
      "issue"
      updateTaskState
    )

class Issue
  constructor: ->
    $('.edit-issue.inline-update input[type="submit"]').hide()
    $(".issue-box .inline-update").on "change", "select", ->
      $(this).submit()
    $(".issue-box .inline-update").on "change", "#issue_assignee_id", ->
      $(this).submit()

    if $("a.btn-close").length
      $("li.task-list-item input:checkbox").prop("disabled", false)

    $(".task-list-item input:checkbox").on "click", ->
      is_checked = $(this).prop("checked")
      if $(this).is(":checked")
        state_event = "task_check"
      else
        state_event = "task_uncheck"

      mr_url = $("form.edit-issue").first().attr("action")
      mr_num = mr_url.match(/\d+$/)
      task_num = 0
      $("li.task-list-item input:checkbox").each( (index, e) =>
        if e == this
          task_num = index + 1
      )

      $.ajax
        type: "PATCH"
        url: mr_url
        data: "issue[state_event]=" + state_event +
          "&issue[task_num]=" + task_num

@Issue = Issue

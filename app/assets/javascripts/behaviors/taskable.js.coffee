window.updateTaskState = (taskableType) ->
  objType = taskableType.data
  isChecked = $(this).prop("checked")
  if $(this).is(":checked")
    stateEvent = "task_check"
  else
    stateEvent = "task_uncheck"

  taskableUrl = $("form.edit-" + objType).first().attr("action")
  taskableNum = taskableUrl.match(/\d+$/)
  taskNum = 0
  $("li.task-list-item input:checkbox").each( (index, e) =>
    if e == this
      taskNum = index + 1
  )

  $.ajax
    type: "PATCH"
    url: taskableUrl
    data: objType + "[state_event]=" + stateEvent +
      "&" + objType + "[task_num]=" + taskNum

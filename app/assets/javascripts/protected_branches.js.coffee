$ ->
  $(".protected-branches-list :checkbox").change (e) ->
    name = $(this).attr("name")
    if name == "developers_can_push"
      id = $(this).val()
      checked = $(this).is(":checked")
      url = $(this).data("url")
      $.ajax
        type: "PUT"
        url: url
        dataType: "json"
        data:
          id: id
          developers_can_push: checked

        success: ->
          row = $(e.target)
          row.closest('tr').effect('highlight')

        error: ->
          new Flash("Failed to update branch!", "alert")

$ ->
  $(".protected-branches-list :checkbox").change (e) ->
    name = $(this).attr("name")
    if name == "developers_can_push" || name == "developers_can_merge"
      id = $(this).val()
      can_push = if $(this).is(":checked") then "1" else "0"
      url = $(this).data("url")
      $.ajax
        type: "PATCH"
        url: url
        dataType: "json"
        data:
          id: id
          protected_branch:
            "#{name}": can_push

        success: ->
          row = $(e.target)
          row.closest('tr').effect('highlight')

        error: ->
          new Flash("Failed to update branch!", "alert")

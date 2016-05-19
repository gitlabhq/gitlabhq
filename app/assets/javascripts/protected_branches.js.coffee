$ ->
  $(".protected-branches-list :checkbox").change (e) ->
    name = $(this).attr("name")
    row = $(this).parents("tr")
    if name == "developers_can_push" || name == "developers_can_merge"
      id = $(this).val()
      can_push = row.find("input[name=developers_can_push]").is(":checked")
      can_merge = row.find("input[name=developers_can_merge]").is(":checked")
      url = $(this).data("url")
      $.ajax
        type: "PUT"
        url: url
        dataType: "json"
        data:
          id: id
          protected_branch:
            developers_can_push: can_push
            developers_can_merge: can_merge

        success: ->
          row = $(e.target)
          row.closest('tr').effect('highlight')

        error: ->
          new Flash("Failed to update branch!", "alert")

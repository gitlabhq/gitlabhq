$ ->
  $(":checkbox").change ->
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
          new Flash("Branch updated.", "notice")
          location.reload true

        error: ->
          new Flash("Failed to update branch!", "alert")

$ ->
  $(":checkbox").change ->
    name = $(this).attr("name")
    if name == "developers_can_push" or name == "developers_can_merge"
      id = $(this).val()
      checkedpush = $("[value=#{id}][name=developers_can_push]").is(":checked")
      checkedmerge = $("[value=#{id}][name=developers_can_merge]").is(":checked")
      url = $(this).data("url")
      $.ajax
        type: "PUT"
        url: url
        dataType: "json"
        data:
          id: id
          developers_can_push: checkedpush
          developers_can_merge: checkedmerge

        success: ->
          new Flash("Branch updated.", "notice")
          location.reload true

        error: ->
          new Flash("Failed to update branch!", "alert")

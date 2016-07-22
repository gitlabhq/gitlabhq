$(function() {
  return $(".protected-branches-list :checkbox").change(function(e) {
    var can_push, id, name, obj, url;
    name = $(this).attr("name");
    if (name === "developers_can_push" || name === "developers_can_merge") {
      id = $(this).val();
      can_push = $(this).is(":checked");
      url = $(this).data("url");
      return $.ajax({
        type: "PATCH",
        url: url,
        dataType: "json",
        data: {
          id: id,
          protected_branch: (
            obj = {},
            obj["" + name] = can_push,
            obj
          )
        },
        success: function() {
          var row;
          row = $(e.target);
          return row.closest('tr').effect('highlight');
        },
        error: function() {
          return new Flash("Failed to update branch!", "alert");
        }
      });
    }
  });
});

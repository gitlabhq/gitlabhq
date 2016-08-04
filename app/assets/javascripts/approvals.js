(function() {
  $(function() {
    $(".approver-list").on("click", ".project-approvers .btn-remove", function() {
      var removeElement = $(this).closest("li");
      var approverId = parseInt(removeElement.attr("id").replace("user_",""));
      var approverIds = $("input#merge_request_approver_ids");
      var skipUsers = approverIds.data("skip-users") || [];
      var approverIndex = skipUsers.indexOf(approverId);

      removeElement.remove();

      if(approverIndex > -1) {
        approverIds.data("skip-users", skipUsers.splice(approverIndex, 1));
      }

      return false;
    });
    $("form.merge-request-form").submit(function() {
      var approver_ids, approvers_input;
      if ($("input#merge_request_approver_ids").length) {
        approver_ids = $.map($("li.project-approvers").not(".approver-template"), function(li, i) {
          return li.id.replace("user_", "");
        });
        approvers_input = $(this).find("input#merge_request_approver_ids");
        approver_ids = approver_ids.concat(approvers_input.val().split(","));
        return approvers_input.val(_.compact(approver_ids).join(","));
      }
    });
    return $(".suggested-approvers a").click(function() {
      var approver_item_html, user_id, user_name;
      user_id = this.id.replace("user_", "");
      user_name = this.text;
      if ($(".approver-list #user_" + user_id).length) {
        return false;
      }
      approver_item_html = $(".project-approvers.approver-template").clone().removeClass("hide approver-template")[0].outerHTML.replace(/\{approver_name\}/g, user_name).replace(/\{user_id\}/g, user_id);
      $(".no-approvers").remove();
      $(".approver-list").append(approver_item_html);
      return false;
    });
  });

}).call(this);

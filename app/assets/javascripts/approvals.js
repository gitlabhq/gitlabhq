(function() {
  $(function() {
    $(".approver-list").on("click", ".unsaved-approvers.approver .btn-remove", function() {
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

    $(".approver-list").on("click", ".unsaved-approvers.approver-group .btn-remove", function() {
      var removeElement = $(this).closest("li");
      var approverGroupId = parseInt(removeElement.attr("id").replace("group_",""));
      var approverGroupIds = $("input#merge_request_approver_group_ids");
      var skipGroups = approverGroupIds.data("skip-groups") || [];
      var approverGroupIndex = skipGroups.indexOf(approverGroupId);

      removeElement.remove();

      if(approverGroupIndex > -1) {
        approverGroupIds.data("skip-groups", skipGroups.splice(approverGroupIndex, 1));
      }

      return false;
    });

    $("form.merge-request-form").submit(function() {
      var approverIds, approversInput, approverGroupIds, approverGroupsInput;

      if ($("input#merge_request_approver_ids").length) {
        approverIds = $.map($("li.unsaved-approvers.approver").not(".approver-template"), function(li, i) {
          return li.id.replace("user_", "");
        });
        approversInput = $(this).find("input#merge_request_approver_ids");
        approverIds = approverIds.concat(approversInput.val().split(","));
        approversInput.val(_.compact(approverIds).join(","));
      }

      if ($("input#merge_request_approver_group_ids").length) {
        approverGroupIds = $.map($("li.unsaved-approvers.approver-group"), function(li, i) {
          return li.id.replace("group_", "");
        });
        approverGroupsInput = $(this).find("input#merge_request_approver_group_ids");
        approverGroupIds = approverGroupIds.concat(approverGroupsInput.val().split(","));
        approverGroupsInput.val(_.compact(approverGroupIds).join(","));
      }
    });

    return $(".suggested-approvers a").click(function() {
      var approver_item_html, user_id, user_name;
      user_id = this.id.replace("user_", "");
      user_name = this.text;
      if ($(".approver-list #user_" + user_id).length) {
        return false;
      }
      approver_item_html = $(".unsaved-approvers.approver-template").clone().removeClass("hide approver-template")[0].outerHTML.replace(/\{approver_name\}/g, user_name).replace(/\{user_id\}/g, user_id);
      $(".no-approvers").remove();
      $(".approver-list").append(approver_item_html);
      return false;
    });
  });

}).call(this);

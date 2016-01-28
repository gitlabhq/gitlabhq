$ ->
  $(".approver-list").on "click", ".project-approvers .btn-remove", ->
    $(this).closest("li").remove()
    return false

  $("form.merge-request-form").submit ->
    if $("input#merge_request_approver_ids").length
      approver_ids = $.map $("li.project-approvers").not(".approver-template"), (li, i) ->
        li.id.replace("user_", "")
      approvers_input = $(this).find("input#merge_request_approver_ids")
      approver_ids = approver_ids.concat(approvers_input.val().split(","))
      approvers_input.val(_.compact(approver_ids).join(","))

  $(".suggested-approvers a").click ->
    user_id = this.id.replace("user_", "")
    user_name = this.text
    return false if $(".approver-list #user_" + user_id).length

    approver_item_html = $(".project-approvers.approver-template").clone().
      removeClass("hide approver-template")[0].
      outerHTML.
      replace(/\{approver_name\}/g, user_name).
      replace(/\{user_id\}/g, user_id)
    $(".no-approvers").remove()
    $(".approver-list").append(approver_item_html)
    return false

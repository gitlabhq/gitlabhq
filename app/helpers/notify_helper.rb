# frozen_string_literal: true

module NotifyHelper
  def merge_request_reference_link(entity, *args)
    link_to(entity.to_reference, merge_request_url(entity, *args))
  end

  def issue_reference_link(entity, *args, full: false)
    link_to(entity.to_reference(full: full), issue_url(entity, *args))
  end

  def work_item_type_for(work_item)
    type = work_item.work_item_type

    # For now we are limiting the scope of the change only for epic work items,
    # we can remove this check to support all work item types.
    type.epic? ? type.base_type : 'issue'
  end

  def merge_request_hash_param(merge_request, reviewer)
    {
      mr_highlight: '<span style="font-weight: 600;color:#333333;">'.html_safe,
      highlight_end: '</span>'.html_safe,
      mr_link: link_to(
        merge_request.to_reference, merge_request_url(merge_request),
        style: "font-weight: 600;color:#3777b0;text-decoration:none"
      ).html_safe,
      reviewer_highlight: '<span>'.html_safe,
      reviewer_avatar: content_tag(
        :img,
        nil,
        height: "24",
        src: avatar_icon_for_user(reviewer, 24, only_path: false),
        style: "border-radius:12px;margin-left:3px;vertical-align:bottom;",
        width: "24",
        alt: "Avatar",
        class: "avatar"
      ).html_safe,
      reviewer_link: link_to(
        reviewer.name,
        user_url(reviewer),
        style: "color:#333333;text-decoration:none;",
        class: "muted"
      ).html_safe
    }
  end
end

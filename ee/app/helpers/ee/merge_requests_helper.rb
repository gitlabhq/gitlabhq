module EE
  module MergeRequestsHelper
    def render_items_list(items, separator = "and")
      items_cnt = items.size

      case items_cnt
      when 1
        items.first
      when 2
        "#{items.first} #{separator} #{items.last}"
      else
        last_item = items.pop
        "#{items.join(", ")} #{separator} #{last_item}"
      end
    end

    # This may be able to be removed with associated specs
    def render_require_section(merge_request)
      str = if merge_request.approvals_left == 1
              "Requires one more approval"
            else
              "Requires #{merge_request.approvals_left} more approvals"
            end

      if merge_request.approvers_left.any?
        more_approvals = merge_request.approvals_left - merge_request.approvers_left.count
        approvers_names = merge_request.approvers_left.map(&:name)

        str << approval_items(more_approvals, approvers_names)
      end

      str
    end

    def approval_items(more_approvals, approvers_names)
      if more_approvals > 0
        " (from #{render_items_list(approvers_names + ["#{more_approvals} more"])})"
      elsif more_approvals < 0
        " (from #{render_items_list(approvers_names, "or")})"
      else
        " (from #{render_items_list(approvers_names)})"
      end
    end
  end
end

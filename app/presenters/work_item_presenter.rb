# frozen_string_literal: true

class WorkItemPresenter < IssuePresenter # rubocop:todo Gitlab/NamespacedClass -- WorkItem is not namespaced
  presents ::WorkItem, as: :work_item

  def duplicated_to_work_item_url
    return unless work_item.duplicated?
    return unless allowed_to_read_work_item?(work_item.duplicated_to)

    Gitlab::UrlBuilder.build(work_item.duplicated_to)
  end

  def moved_to_work_item_url
    return unless work_item.moved?
    return unless allowed_to_read_work_item?(work_item.moved_to)

    Gitlab::UrlBuilder.build(work_item.moved_to)
  end

  private

  def allowed_to_read_work_item?(item)
    Ability.allowed?(current_user, :read_work_item, item)
  end
end

WorkItemPresenter.prepend_mod_with('WorkItemPresenter')

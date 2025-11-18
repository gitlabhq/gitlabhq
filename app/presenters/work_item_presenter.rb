# frozen_string_literal: true

class WorkItemPresenter < IssuePresenter # rubocop:todo Gitlab/NamespacedClass -- WorkItem is not namespaced
  extend ::Gitlab::Utils::Override

  presents ::WorkItem, as: :work_item

  override :web_url
  def web_url
    return super unless should_use_work_item_path?

    work_item_url_helper(only_path: false)
  end

  override :web_path
  def web_path
    return super unless should_use_work_item_path?

    work_item_url_helper(only_path: true)
  end

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

  def should_use_work_item_path?
    work_item.resource_parent&.work_items_consolidated_list_enabled?(current_user) && work_item.show_as_work_item?
  end

  def work_item_url_helper(only_path:)
    Gitlab::Routing.url_helpers.polymorphic_url([work_item.namespace.owner_entity, work_item], only_path: only_path)
  end
end

WorkItemPresenter.prepend_mod_with('WorkItemPresenter')

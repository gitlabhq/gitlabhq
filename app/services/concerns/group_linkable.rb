# frozen_string_literal: true

module GroupLinkable
  extend ActiveSupport::Concern

  def execute
    remove_unallowed_params

    return error('Not Found', 404) unless valid_to_create?

    build_link

    if link.save
      after_successful_save
      success(link: link)
    else
      error(link.errors.full_messages.to_sentence, 409)
    end
  end

  private

  attr_reader :shared_with_group, :link

  def sharing_allowed?
    sharing_outside_hierarchy_allowed? || within_hierarchy?
  end

  def sharing_outside_hierarchy_allowed?
    !root_ancestor.prevent_sharing_groups_outside_hierarchy
  end

  def within_hierarchy?
    root_ancestor.self_and_descendants_ids.include?(shared_with_group.id)
  end

  def after_successful_save
    setup_authorizations
  end
end

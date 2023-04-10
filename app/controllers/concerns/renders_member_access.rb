# frozen_string_literal: true

module RendersMemberAccess
  def prepare_groups_for_rendering(groups)
    preload_max_member_access_for_collection(Group, groups)

    groups
  end

  private

  # rubocop: disable CodeReuse/ActiveRecord
  def preload_max_member_access_for_collection(klass, collection)
    return if !current_user || collection.blank?

    method_name = "max_member_access_for_#{klass.name.underscore}_ids"

    collection_ids = collection.try(:map, &:id) || collection.ids
    current_user.public_send(method_name, collection_ids) # rubocop:disable GitlabSecurity/PublicSend
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

# frozen_string_literal: true

module API
  module Entities
    class SharedGroupWithProject < Grape::Entity
      expose :group_id
      expose :group_name do |group_link, options|
        group_link.group.name
      end
      expose :group_full_path do |group_link, options|
        group_link.group.full_path
      end
      expose :group_access, as: :group_access_level
      expose :expires_at
    end
  end
end

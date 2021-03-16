# frozen_string_literal: true

module API
  module Entities
    class PublicGroupDetails < BasicGroupDetails
      expose :avatar_url do |group, options|
        group.avatar_url(only_path: false)
      end
      expose :full_name, :full_path
    end
  end
end

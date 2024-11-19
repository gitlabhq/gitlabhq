# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Maven
      class Registry < ApplicationRecord
        ignore_column :cache_validity_hours, remove_with: '17.8', remove_after: '2024-12-23'

        belongs_to :group
        has_one :registry_upstream,
          class_name: 'VirtualRegistries::Packages::Maven::RegistryUpstream',
          inverse_of: :registry
        has_one :upstream, class_name: 'VirtualRegistries::Packages::Maven::Upstream', through: :registry_upstream

        validates :group, top_level_group: true, presence: true, uniqueness: true

        scope :for_group, ->(group) { where(group: group) }

        before_destroy :destroy_upstream

        private

        # TODO: revisit this when we support multiple upstreams.
        # https://gitlab.com/gitlab-org/gitlab/-/issues/480461
        def destroy_upstream
          upstream&.destroy!
        end
      end
    end
  end
end

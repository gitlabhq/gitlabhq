# frozen_string_literal: true

module Ci
  class ResourceGroup < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project, inverse_of: :resource_groups

    has_many :resources, class_name: 'Ci::Resource', inverse_of: :resource_group
    has_many :builds, class_name: 'Ci::Build', inverse_of: :resource_group

    validates :key,
      length: { maximum: 255 },
      format: { with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message }

    before_create :ensure_resource

    def retain_resource_for(build)
      resources.free.limit(1).update_all(build_id: build.id) > 0
    end

    def release_resource_from(build)
      resources.retained_by(build).update_all(build_id: nil) > 0
    end

    private

    def ensure_resource
      # Currently we only support one resource per group, which means
      # maximum one build can be set to the resource group, thus builds
      # belong to the same resource group are executed once at time.
      self.resources.build if self.resources.empty?
    end
  end
end

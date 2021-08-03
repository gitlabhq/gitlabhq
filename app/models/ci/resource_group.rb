# frozen_string_literal: true

module Ci
  class ResourceGroup < Ci::ApplicationRecord
    belongs_to :project, inverse_of: :resource_groups

    has_many :resources, class_name: 'Ci::Resource', inverse_of: :resource_group
    has_many :processables, class_name: 'Ci::Processable', inverse_of: :resource_group

    validates :key,
      length: { maximum: 255 },
      format: { with: Gitlab::Regex.environment_name_regex,
                message: Gitlab::Regex.environment_name_regex_message }

    before_create :ensure_resource

    ##
    # NOTE: This is concurrency-safe method that the subquery in the `UPDATE`
    # works as explicit locking.
    def assign_resource_to(processable)
      resources.free.limit(1).update_all(build_id: processable.id) > 0
    end

    def release_resource_from(processable)
      resources.retained_by(processable).update_all(build_id: nil) > 0
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

# frozen_string_literal: true

module Ci
  class PendingBuild < Ci::ApplicationRecord
    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'

    scope :ref_protected, -> { where(protected: true) }
    scope :queued_before, ->(time) { where(arel_table[:created_at].lt(time)) }

    def self.upsert_from_build!(build)
      entry = self.new(args_from_build(build))

      entry.validate!

      self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
    end

    def self.args_from_build(build)
      args = {
        build: build,
        project: build.project,
        protected: build.protected?
      }

      if Feature.enabled?(:ci_pending_builds_maintain_shared_runners_data, type: :development, default_enabled: :yaml)
        args.merge(instance_runners_enabled: shareable?(build))
      else
        args
      end
    end
    private_class_method :args_from_build

    def self.shareable?(build)
      shared_runner_enabled?(build) &&
        builds_access_level?(build) &&
        project_not_removed?(build)
    end
    private_class_method :shareable?

    def self.shared_runner_enabled?(build)
      build.project.shared_runners.exists?
    end
    private_class_method :shared_runner_enabled?

    def self.project_not_removed?(build)
      !build.project.pending_delete?
    end
    private_class_method :project_not_removed?

    def self.builds_access_level?(build)
      build.project.project_feature.builds_access_level.nil? || build.project.project_feature.builds_access_level > 0
    end
    private_class_method :builds_access_level?
  end
end

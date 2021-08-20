# frozen_string_literal: true

module Ci
  class PendingBuild < Ci::ApplicationRecord
    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'
    belongs_to :namespace, inverse_of: :pending_builds, class_name: 'Namespace'

    validates :namespace, presence: true

    scope :ref_protected, -> { where(protected: true) }
    scope :queued_before, ->(time) { where(arel_table[:created_at].lt(time)) }
    scope :with_instance_runners, -> { where(instance_runners_enabled: true) }

    class << self
      def upsert_from_build!(build)
        entry = self.new(args_from_build(build))

        entry.validate!

        self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
      end

      private

      def args_from_build(build)
        args = {
          build: build,
          project: build.project,
          protected: build.protected?,
          namespace: build.project.namespace
        }

        if Feature.enabled?(:ci_pending_builds_maintain_tags_data, type: :development, default_enabled: :yaml)
          args.store(:tag_ids, build.tags_ids)
        end

        if Feature.enabled?(:ci_pending_builds_maintain_shared_runners_data, type: :development, default_enabled: :yaml)
          args.store(:instance_runners_enabled, shareable?(build))
        end

        args
      end

      def shareable?(build)
        shared_runner_enabled?(build) &&
          builds_access_level?(build) &&
          project_not_removed?(build)
      end

      def shared_runner_enabled?(build)
        build.project.shared_runners.exists?
      end

      def project_not_removed?(build)
        !build.project.pending_delete?
      end

      def builds_access_level?(build)
        build.project.project_feature.builds_access_level.nil? ||
          build.project.project_feature.builds_access_level > 0
      end
    end
  end
end

Ci::PendingBuild.prepend_mod_with('Ci::PendingBuild')

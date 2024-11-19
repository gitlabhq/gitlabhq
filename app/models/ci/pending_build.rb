# frozen_string_literal: true

module Ci
  class PendingBuild < Ci::ApplicationRecord
    include EachBatch
    include Ci::Partitionable

    belongs_to :project

    belongs_to :build, # rubocop: disable Rails/InverseOf -- this relation is not present on build
      ->(pending_build) { in_partition(pending_build) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id
    belongs_to :namespace, inverse_of: :pending_builds, class_name: 'Namespace'
    belongs_to :plan

    partitionable scope: :build

    validates :namespace, presence: true

    scope :ref_protected, -> { where(protected: true) }
    scope :with_instance_runners, -> { where(instance_runners_enabled: true) }
    scope :for_tags, ->(tag_ids) do
      if tag_ids.present?
        where("ci_pending_builds.tag_ids <@ '{?}'", Array.wrap(tag_ids))
      else
        where("ci_pending_builds.tag_ids = '{}'")
      end
    end

    class << self
      def upsert_from_build!(build)
        entry = self.new(args_from_build(build))

        entry.validate!

        self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
      end

      def namespace_transfer_params(namespace)
        {
          namespace_traversal_ids: namespace.traversal_ids,
          namespace_id: namespace.id
        }
      end

      private

      def args_from_build(build)
        project = build.project

        args = {
          build: build,
          project: project,
          protected: build.protected?,
          namespace: project.namespace,
          tag_ids: build.tags_ids,
          instance_runners_enabled: shared_runners_enabled?(project)
        }

        args.store(:namespace_traversal_ids, project.namespace.traversal_ids) if group_runners_enabled?(project)

        args
      end

      def shared_runners_enabled?(project)
        builds_enabled?(project) && project.shared_runners_enabled?
      end

      def group_runners_enabled?(project)
        builds_enabled?(project) && project.group_runners_enabled?
      end

      def builds_enabled?(project)
        project.builds_enabled? && !project.pending_delete?
      end
    end
  end
end

Ci::PendingBuild.prepend_mod_with('Ci::PendingBuild')

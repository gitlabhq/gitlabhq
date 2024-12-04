# frozen_string_literal: true

require_dependency 'design_management'

module DesignManagement
  class Action < ApplicationRecord
    include WithUploads

    self.table_name = "#{DesignManagement.table_name_prefix}designs_versions"

    mount_uploader :image_v432x230, DesignManagement::DesignV432x230Uploader

    belongs_to :design, class_name: "DesignManagement::Design", inverse_of: :actions
    belongs_to :version, class_name: "DesignManagement::Version", inverse_of: :actions

    enum event: { creation: 0, modification: 1, deletion: 2 }

    # we assume sequential ordering.
    scope :ordered, -> { order(version_id: :asc) }
    scope :by_design, ->(design) { where(design: design) }
    scope :by_event, ->(event) { where(event: event) }
    scope :with_version, -> { preload(:version) }

    # For each design, only select the most recent action
    scope :most_recent, -> do
      selection = Arel.sql("DISTINCT ON (#{table_name}.design_id) #{table_name}.*")

      order(arel_table[:design_id].asc, arel_table[:version_id].desc).select(selection)
    end

    # Find all records created before or at the given version, or all if nil
    scope :up_to_version, ->(version = nil) do
      case version
      when nil
        all
      when DesignManagement::Version
        where(arel_table[:version_id].lteq(version.id))
      when ::Gitlab::Git::COMMIT_ID
        versions = DesignManagement::Version.arel_table
        subquery = versions.project(versions[:id]).where(versions[:sha].eq(version))
        where(arel_table[:version_id].lteq(subquery))
      else
        raise ArgumentError, "Expected a DesignManagement::Version, got #{version}"
      end
    end

    def uploads_sharding_key
      { namespace_id: design&.namespace_id }
    end
  end
end

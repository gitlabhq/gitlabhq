# frozen_string_literal: true

module Packages
  module Maven
    class GroupsAndProjectsPackageFilesFinder
      include Gitlab::Utils::StrongMemoize

      # main client of this finder is the maven virtual registry.
      # Given the restrictions on the maven upstreams in a registry,
      # that client will send max 20 ids.
      MAX_IDS_COUNT = 20

      def initialize(path:, project_ids: [], group_ids: [])
        @project_ids = project_ids
        @group_ids = group_ids
        @path = path
      end

      def execute
        return ::Packages::PackageFile.none unless valid?

        # rubocop: disable CodeReuse/ActiveRecord -- highly specific query
        inner_query = ::Packages::PackageFile
          .with(metadatum_cte.to_arel)
          .installable
          .for_package_ids(packages)
          .with_file_name(filename)
          .select('DISTINCT ON (package_id) packages_package_files.*')
          .reorder('package_id, id DESC')
          .limit(MAX_IDS_COUNT)

        ::Packages::PackageFile
          .from(inner_query, :packages_package_files)
          .reorder(id: :desc)
        # rubocop: enable CodeReuse/ActiveRecord
      end

      private

      attr_reader :project_ids, :group_ids, :path

      def valid?
        return false if project_ids.blank? && group_ids.blank?
        return false if project_ids.size + group_ids.size > MAX_IDS_COUNT
        return false unless folder_path.present? && filename.present?

        true
      end

      def packages
        ::Packages::Maven::Package
          .installable
          .joins('INNER JOIN maven_metadata_by_path ON maven_metadata_by_path.package_id=packages_packages.id') # rubocop: disable CodeReuse/ActiveRecord -- highly specific query
      end

      def group_projects
        Project.by_any_overlap_with_traversal_ids(group_ids)
      end

      def metadatum_cte
        base_query = Packages::Maven::Metadatum.with_path(folder_path).select(:id, :package_id)
        cte_query = if project_ids.any? && group_ids.any?
                      base_query.for_project_ids(project_ids).or(base_query.for_project_ids(group_projects))
                    elsif project_ids.any?
                      base_query.for_project_ids(project_ids)
                    else
                      base_query.for_project_ids(group_projects)
                    end

        Gitlab::SQL::CTE.new(:maven_metadata_by_path, cte_query)
      end

      def folder_path
        path.rpartition('/').first
      end
      strong_memoize_attr :folder_path

      def filename
        path.rpartition('/').last
      end
      strong_memoize_attr :filename
    end
  end
end

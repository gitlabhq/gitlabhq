# frozen_string_literal: true

module Packages
  module Nuget
    class SearchService < BaseService
      include Gitlab::Utils::StrongMemoize
      include ActiveRecord::ConnectionAdapters::Quoting

      MAX_PER_PAGE = 30
      MAX_VERSIONS_PER_PACKAGE = 10
      PRE_RELEASE_VERSION_MATCHING_TERM = '%-%'

      DEFAULT_OPTIONS = {
        include_prerelease_versions: true,
        per_page: Kaminari.config.default_per_page,
        padding: 0
      }.freeze

      def initialize(project, search_term, options = {})
        @project = project
        @search_term = search_term
        @options = DEFAULT_OPTIONS.merge(options)

        raise ArgumentError, 'negative per_page' if per_page < 0
        raise ArgumentError, 'negative padding' if padding < 0
      end

      def execute
        OpenStruct.new(
          total_count: package_names.total_count,
          results: search_packages
        )
      end

      private

      def search_packages
        # custom query to get package names and versions as expected from the nuget search api
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24182#technical-notes
        # and https://docs.microsoft.com/en-us/nuget/api/search-query-service-resource
        subquery_name = :partition_subquery
        arel_table = Arel::Table.new(:partition_subquery)
        column_names = Packages::Package.column_names.map do |cn|
          "#{subquery_name}.#{quote_column_name(cn)}"
        end

        # rubocop: disable CodeReuse/ActiveRecord
        pkgs = Packages::Package.select(column_names.join(','))
                                .from(package_names_partition, subquery_name)
                                .where(arel_table[:row_number].lteq(MAX_VERSIONS_PER_PACKAGE))

        return pkgs if include_prerelease_versions?

        # we can't use pkgs.without_version_like since we have a custom from
        pkgs.where.not(arel_table[:version].matches(PRE_RELEASE_VERSION_MATCHING_TERM))
      end

      def package_names_partition
        table_name = quote_table_name(Packages::Package.table_name)
        name_column = "#{table_name}.#{quote_column_name('name')}"
        created_at_column = "#{table_name}.#{quote_column_name('created_at')}"
        select_sql = "ROW_NUMBER() OVER (PARTITION BY #{name_column} ORDER BY #{created_at_column} DESC) AS row_number, #{table_name}.*"

        @project.packages
                .select(select_sql)
                .nuget
                .has_version
                .without_nuget_temporary_name
                .with_name(package_names)
      end

      def package_names
        strong_memoize(:package_names) do
          pkgs = @project.packages
                         .nuget
                         .has_version
                         .without_nuget_temporary_name
                         .order_name
                         .select_distinct_name
          pkgs = pkgs.without_version_like(PRE_RELEASE_VERSION_MATCHING_TERM) unless include_prerelease_versions?
          pkgs = pkgs.search_by_name(@search_term) if @search_term.present?
          pkgs.page(0) # we're using a padding
              .per(per_page)
              .padding(padding)
        end
      end

      def include_prerelease_versions?
        @options[:include_prerelease_versions]
      end

      def padding
        @options[:padding]
      end

      def per_page
        [@options[:per_page], MAX_PER_PAGE].min
      end
    end
  end
end

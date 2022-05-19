# frozen_string_literal: true

module Packages
  class BuildInfosFinder
    include ActiveRecord::ConnectionAdapters::Quoting

    MAX_PAGE_SIZE = 100

    def initialize(package_ids, params)
      @package_ids = package_ids
      @params = params
    end

    def execute
      return Packages::BuildInfo.none if @package_ids.blank?

      # This is a highly custom query that
      # will not be re-used elsewhere
      # rubocop: disable CodeReuse/ActiveRecord
      query = Packages::Package.id_in(@package_ids)
                .select('build_infos.*')
                .from([Packages::Package.arel_table, lateral_query.arel.lateral.as('build_infos')])
                .order('build_infos.id DESC')

      # We manually select build_infos fields from the lateral query.
      # Thus, we need to instruct ActiveRecord that returned rows are
      # actually Packages::BuildInfo objects
      Packages::BuildInfo.find_by_sql(query.to_sql)
      # rubocop: enable CodeReuse/ActiveRecord
    end

    private

    def lateral_query
      order_direction = last ? :asc : :desc

      # This is a highly custom query that
      # will not be re-used elsewhere
      # rubocop: disable CodeReuse/ActiveRecord
      where_condition = Packages::BuildInfo.arel_table[:package_id]
                          .eq(Arel.sql("#{Packages::Package.table_name}.id"))
      build_infos = ::Packages::BuildInfo.without_empty_pipelines
                      .where(where_condition)
                      .order(id: order_direction)
                      .limit(max_rows_per_package_id)
      # rubocop: enable CodeReuse/ActiveRecord
      apply_cursor(build_infos)
    end

    def max_rows_per_package_id
      limit = [first, last, max_page_size, MAX_PAGE_SIZE].compact.min
      limit += 1 if support_next_page
      limit
    end

    def apply_cursor(build_infos)
      if before
        build_infos.with_pipeline_id_greater_than(before)
      elsif after
        build_infos.with_pipeline_id_less_than(after)
      else
        build_infos
      end
    end

    def first
      @params[:first]
    end

    def last
      @params[:last]
    end

    def max_page_size
      @params[:max_page_size]
    end

    def before
      @params[:before]
    end

    def after
      @params[:after]
    end

    def support_next_page
      @params[:support_next_page]
    end
  end
end

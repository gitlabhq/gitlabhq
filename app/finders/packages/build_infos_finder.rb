# frozen_string_literal: true

module Packages
  class BuildInfosFinder
    MAX_PAGE_SIZE = 100

    def initialize(package, params)
      @package = package
      @params = params
    end

    def execute
      build_infos = @package.build_infos.without_empty_pipelines
      build_infos = apply_order(build_infos)
      build_infos = apply_limit(build_infos)
      apply_cursor(build_infos)
    end

    private

    def apply_order(build_infos)
      order_direction = :desc
      order_direction = :asc if last

      build_infos.order_by_pipeline_id(order_direction)
    end

    def apply_limit(build_infos)
      limit = [first, last, max_page_size, MAX_PAGE_SIZE].compact.min
      limit += 1 if support_next_page
      build_infos.limit(limit)
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

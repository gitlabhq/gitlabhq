# frozen_string_literal: true

module Bitbucket # rubocop:disable Gitlab/BoundedContexts -- existing module
  class MultiWorkspaceCollection < Enumerator
    DEFAULT_LIMIT = 25

    attr_reader :limit, :total_fetched_items_count, :workspace_configs, :workspace_paging_info

    def initialize(workspace_configs, connection, limit: DEFAULT_LIMIT)
      @workspace_configs = workspace_configs
      @connection = connection
      @limit = limit
      @total_fetched_items_count = 0
      @workspace_paging_info = []

      super() do |yielder|
        workspace_configs.each do |config|
          process_workspace_config(config, yielder)
        end
      end

      lazy
    end

    def page_info
      {
        has_next_page: workspace_paging_info.any? { |i| i.dig(:page_info, :has_next_page) }
      }
    end

    private

    def process_workspace_config(config, yielder)
      if should_skip_workspace?
        add_unfetched_workspace_info(config)

        return
      end

      collection = create_workspace_collection(config)
      process_workspace_items(collection, yielder, config[:workspace])
    end

    def should_skip_workspace?
      total_fetched_items_count >= limit
    end

    def add_unfetched_workspace_info(config)
      @workspace_paging_info << {
        workspace: config[:workspace],
        page_info: {
          has_next_page: true,
          next_page: config[:page_number] || 1
        }
      }
    end

    def create_workspace_collection(config)
      paginator = Bitbucket::Paginator.new(
        @connection,
        config[:path],
        config[:type],
        page_number: config[:page_number],
        limit: limit
      )

      Bitbucket::Collection.new(paginator)
    end

    def process_workspace_items(collection, yielder, workspace_slug)
      collection.each do |item|
        yielder << item

        @total_fetched_items_count += 1
      end

      page_info = collection.page_info

      return unless page_info[:has_next_page]

      @workspace_paging_info << {
        workspace: workspace_slug,
        page_info: page_info.slice(:has_next_page, :next_page)
      }
    end
  end
end

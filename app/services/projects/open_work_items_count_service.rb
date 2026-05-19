# frozen_string_literal: true

module Projects
  # Service class for counting and caching the number of open work items of a project.
  class OpenWorkItemsCountService < Projects::CountService
    PUBLIC_COUNT_KEY = 'public_open_work_items_count'
    TOTAL_COUNT_KEY  = 'total_open_work_items_count'

    def initialize(project, user = nil)
      @user = user
      super(project)
    end

    def cache_key_name
      public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
    end

    def public_only?
      !Ability.allowed?(@user, :read_confidential_issues, @project)
    end

    def relation_for_count
      self.class.query(@project, public_only: public_only?)
    end

    def public_count_cache_key
      cache_key(PUBLIC_COUNT_KEY)
    end

    def total_count_cache_key
      cache_key(TOTAL_COUNT_KEY)
    end

    def delete_cache
      [public_count_cache_key, total_count_cache_key].each do |key|
        Rails.cache.delete(key)
      end
    end

    class << self
      # rubocop: disable CodeReuse/ActiveRecord -- query method is the accepted pattern in CountService subclasses
      def query(projects, public_only: true)
        open_work_items = base_query.limit(WorkItem::MAX_OPEN_WORK_ITEMS_COUNT)

        if public_only
          open_work_items.public_only.where(project: projects)
        else
          open_work_items.where(project: projects)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      # Override in EE to add type filters (e.g. exclude :requirement).
      def base_query
        WorkItem.opened.without_hidden
      end
    end
  end
end

Projects::OpenWorkItemsCountService.prepend_mod

# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open work items of a group.
  class OpenWorkItemsCountService < Groups::CountService
    extend ::Gitlab::Utils::Override

    PUBLIC_COUNT_KEY = 'group_public_open_work_items_count'
    TOTAL_COUNT_KEY  = 'group_total_open_work_items_count'
    OPEN_WORK_ITEMS_CACHE_KEY = 'open_work_items'

    override :initialize
    def initialize(*args, fast_timeout: false)
      super(*args)

      @fast_timeout = fast_timeout
    end

    def clear_all_cache_keys
      [cache_key(PUBLIC_COUNT_KEY), cache_key(TOTAL_COUNT_KEY)].each do |key|
        Rails.cache.delete(key)
      end
    end

    private

    override :uncached_count
    def uncached_count
      return super unless @fast_timeout

      ApplicationRecord.with_fast_read_statement_timeout do # rubocop:disable Performance/ActiveRecordSubtransactionMethods -- this is called outside a transaction
        super
      end
    end

    def cache_key_name
      public_only? ? PUBLIC_COUNT_KEY : TOTAL_COUNT_KEY
    end

    def public_only?
      !Ability.allowed?(user, :read_confidential_issues, group)
    end

    def relation_for_count
      confidential_filter = public_only? ? false : nil

      WorkItems::WorkItemsFinder.new(
        user,
        group_id: group.id,
        state: 'opened',
        non_archived: true,
        include_descendants: true,
        confidential: confidential_filter
      ).execute.limit(WorkItem::MAX_OPEN_WORK_ITEMS_COUNT)
    end

    def issuable_key
      OPEN_WORK_ITEMS_CACHE_KEY
    end
  end
end

Groups::OpenWorkItemsCountService.prepend_mod

# frozen_string_literal: true

module Database
  class ConsistencyFixService
    def initialize(source_model:, target_model:, sync_event_class:, source_sort_key:, target_sort_key:)
      @source_model = source_model
      @target_model = target_model
      @sync_event_class = sync_event_class
      @source_sort_key = source_sort_key
      @target_sort_key = target_sort_key
    end

    attr_accessor :source_model, :target_model, :sync_event_class, :source_sort_key, :target_sort_key

    def execute(ids:)
      ids.each do |id|
        if source_object(id) && target_object(id)
          create_sync_event_for(id)
        elsif target_object(id)
          target_object(id).destroy!
        end
      end
      sync_event_class.enqueue_worker
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def source_object(id)
      source_model.find_by(source_sort_key => id)
    end

    def target_object(id)
      target_model.find_by(target_sort_key => id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_sync_event_for(id)
      if source_model == Namespace
        sync_event_class.create!(namespace_id: id)
      elsif source_model == Project
        sync_event_class.create!(project_id: id)
      else
        raise("Unknown Source Model #{source_model.name}")
      end
    end
  end
end

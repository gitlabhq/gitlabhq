# frozen_string_literal: true

module WorkItems
  class BaseEvent < Gitlab::EventStore::CloudEvent
    event_category :work_items

    class << self
      protected

      def build_for_work_item(work_item:, current_user:, extra_event_data: {})
        build_cloud_event(
          source: "projects/#{work_item.project.id}",
          subject: "work_items/#{work_item.id}",
          current_user: current_user,
          organization: work_item.project.organization,
          event_data: work_item_event_data(work_item).merge(extra_event_data)
        )
      end

      private

      def work_item_event_data(work_item)
        {
          work_item_id: work_item.id,
          work_item_iid: work_item.iid,
          namespace_id: work_item.namespace_id,
          project_id: work_item.project_id,
          work_item_type: work_item.work_item_type.base_type,
          confidential: work_item.confidential
        }
      end
    end

    def data_schema
      {
        'type' => 'object',
        'properties' => base_properties.merge(additional_properties),
        'required' => base_required + additional_required
      }
    end

    private

    def base_properties
      {
        'work_item_id' => { 'type' => 'integer' },
        'work_item_iid' => { 'type' => 'integer' },
        'namespace_id' => { 'type' => 'integer' },
        'project_id' => { 'type' => 'integer' },
        'work_item_type' => { 'type' => 'string' },
        'confidential' => { 'type' => 'boolean' }
      }
    end

    def base_required
      %w[work_item_id work_item_iid namespace_id project_id work_item_type confidential]
    end

    # Override in subclasses to add event specific schema properties
    def additional_properties
      {}
    end

    # Override in subclasses to add event specific required fields
    def additional_required
      []
    end
  end
end

# frozen_string_literal: true

# This class is a simplified version of assign_nested_attributes_for_collection_association from ActiveRecord
# https://github.com/rails/rails/blob/v6.0.2.1/activerecord/lib/active_record/nested_attributes.rb#L466

module Ci
  class UpdateInstanceVariablesService
    UNASSIGNABLE_KEYS = %w(id _destroy).freeze

    def initialize(params)
      @params = params[:variables_attributes]
    end

    def execute
      instantiate_records
      persist_records
    end

    def errors
      @records.to_a.flat_map { |r| r.errors.full_messages }
    end

    private

    attr_reader :params

    def existing_records_by_id
      @existing_records_by_id ||= Ci::InstanceVariable
        .all
        .index_by { |var| var.id.to_s }
    end

    def instantiate_records
      @records = params.map do |attributes|
        find_or_initialize_record(attributes).tap do |record|
          record.assign_attributes(attributes.except(*UNASSIGNABLE_KEYS))
          record.mark_for_destruction if has_destroy_flag?(attributes)
        end
      end
    end

    def find_or_initialize_record(attributes)
      id = attributes[:id].to_s

      if id.blank?
        Ci::InstanceVariable.new
      else
        existing_records_by_id.fetch(id) { raise ActiveRecord::RecordNotFound }
      end
    end

    def persist_records
      Ci::InstanceVariable.transaction do
        success = @records.map do |record|
          if record.marked_for_destruction?
            record.destroy
          else
            record.save
          end
        end.all?

        raise ActiveRecord::Rollback unless success

        success
      end
    end

    def has_destroy_flag?(hash)
      Gitlab::Utils.to_boolean(hash['_destroy'])
    end
  end
end

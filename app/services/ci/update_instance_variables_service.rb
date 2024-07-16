# frozen_string_literal: true

# This class is a simplified version of assign_nested_attributes_for_collection_association from ActiveRecord
# https://github.com/rails/rails/blob/v6.0.2.1/activerecord/lib/active_record/nested_attributes.rb#L466

module Ci
  class UpdateInstanceVariablesService
    UNASSIGNABLE_KEYS = %w[id _destroy].freeze

    def initialize(params, current_user)
      @current_user = current_user
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

    attr_reader :params, :current_user

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

    # overridden in EE
    def audit_change(instance_variable); end

    def persist_records
      changes = []
      success = false

      Ci::InstanceVariable.transaction do
        changes = @records.map do |record|
          if record.marked_for_destruction?
            { action: record.destroy, record: record }
          else
            { action: record.save, record: record }
          end
        end
        success = changes.all? { |change| change[:action] }

        raise ActiveRecord::Rollback unless success
      end

      changes.each { |change| audit_change change[:record] }

      success
    end

    def has_destroy_flag?(hash)
      Gitlab::Utils.to_boolean(hash['_destroy'])
    end
  end
end
Ci::UpdateInstanceVariablesService.prepend_mod

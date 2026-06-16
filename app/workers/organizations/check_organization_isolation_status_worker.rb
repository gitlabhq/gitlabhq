# frozen_string_literal: true

module Organizations
  class CheckOrganizationIsolationStatusWorker
    include ApplicationWorker

    feature_category :organization
    data_consistency :sticky
    idempotent!

    def perform(model_class, record_id, changes)
      model = model_class.safe_constantize
      return unless model.is_a?(Class) && model < ActiveRecord::Base

      # `record_id` may be a composite primary key (e.g. [follower_id, followee_id]
      # for Users::UserFollowUser), which only `find` supports: `find_by(id:)`
      # does not. We rescue RecordNotFound so the worker no-ops if the record
      # was deleted between enqueue and execution.
      record = begin
        model.find(record_id) # rubocop:disable Gitlab/NoFindInWorkers -- see comment above; RecordNotFound is rescued
      rescue ActiveRecord::RecordNotFound
        nil
      end

      return unless record && expected_state?(record, changes)

      # Transform database column name into method names
      changed_associations = changed_associations(model, changes)

      Gitlab::Organizations::IsolationStatus.new(record, changed_associations).verify!
    end

    private

    def expected_state?(record, changes)
      changes.all? do |attribute, (_, new_value)|
        record.read_attribute(attribute) == new_value
      end
    end

    def changed_associations(model_class, changes)
      model_class
        .reflect_on_all_associations(:belongs_to)
        .filter_map { |belongs_to| belongs_to.name if belongs_to.foreign_key.in?(changes.keys) }
    end
  end
end

# frozen_string_literal: true

module Ci
  module Partitionable
    # Used to patch the save, update, delete, destroy methods to use the
    # partition_id attributes for their SQL queries.
    module PartitionedFilter
      extend ActiveSupport::Concern

      if Rails::VERSION::MAJOR >= 7
        # These methods are updated in Rails 7 to use `_primary_key_constraints_hash`
        # by default, so this patch will no longer be required.
        #
        # rubocop:disable Gitlab/NoCodeCoverageComment
        # :nocov:
        raise "`#{__FILE__}` should be double checked" if Rails.env.test?

        warn "Update `#{__FILE__}`. Patches Rails internals for partitioning"
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment
      else
        def _update_row(attribute_names, attempted_action = "update")
          self.class._update_record(
            attributes_with_values(attribute_names),
            _primary_key_constraints_hash
          )
        end

        def _delete_row
          self.class._delete_record(_primary_key_constraints_hash)
        end
      end

      # Introduced in Rails 7, but updated to include `partition_id` filter.
      # https://github.com/rails/rails/blob/a4dbb153fd390ac31bb9808809e7ac4d3a2c5116/activerecord/lib/active_record/persistence.rb#L1031-L1033
      def _primary_key_constraints_hash
        { @primary_key => id_in_database, partition_id: partition_id }  # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end
    end
  end
end

# frozen_string_literal: true

# ensure ActiveRecord's version has been required already
require 'active_record/locking/optimistic'

# rubocop:disable Lint/RescueException
module ActiveRecord
  module Locking
    module Optimistic
      private

      def _update_row(attribute_names, attempted_action = "update")
        return super unless locking_enabled?

        begin
          locking_column = self.class.locking_column
          previous_lock_value = read_attribute_before_type_cast(locking_column)
          attribute_names << locking_column

          self[locking_column] += 1

          # Patched because when `lock_version` is read as `0`, it may actually be `NULL` in the DB.
          possible_previous_lock_value = previous_lock_value.to_i == 0 ? [nil, 0] : previous_lock_value

          affected_rows = self.class.unscoped.where(
            locking_column => possible_previous_lock_value,
            self.class.primary_key => id_in_database
          ).update_all(
            attributes_with_values_for_update(attribute_names)
          )

          if affected_rows != 1
            raise ActiveRecord::StaleObjectError.new(self, attempted_action)
          end

          affected_rows

        # If something went wrong, revert the locking_column value.
        rescue Exception
          self[locking_column] = previous_lock_value.to_i
          raise
        end
      end
    end
  end
end

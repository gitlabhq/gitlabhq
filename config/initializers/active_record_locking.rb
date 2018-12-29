# rubocop:disable Lint/RescueException

# Remove this monkey patch when we move to Rails 5.1, because the bug has been fixed in https://github.com/rails/rails/pull/26050.
if Rails.gem_version >= Gem::Version.new("5.1")
  raise "Remove this monkey patch: #{__FILE__}"
end

module ActiveRecord
  module Locking
    module Optimistic
      # We overwrite this method because we don't want to have default value
      # for newly created records
      def _create_record(attribute_names = self.attribute_names, *) # :nodoc:
        super
      end

      def _update_record(attribute_names = self.attribute_names) #:nodoc:
        return super unless locking_enabled?
        return 0 if attribute_names.empty?

        lock_col = self.class.locking_column
        previous_lock_value = send(lock_col).to_i
        increment_lock

        attribute_names += [lock_col]
        attribute_names.uniq!

        begin
          relation = self.class.unscoped

          affected_rows = relation.where(
            self.class.primary_key => id,
            # Patched because when `lock_version` is read as `0`, it may actually be `NULL` in the DB.
            lock_col => previous_lock_value == 0 ? [nil, 0] : previous_lock_value
          ).update_all(
            attributes_for_update(attribute_names).map do |name|
              [name, _read_attribute(name)]
            end.to_h
          )

          unless affected_rows == 1
            raise ActiveRecord::StaleObjectError.new(self, "update")
          end

          affected_rows

        # If something went wrong, revert the version.
        rescue Exception
          send(lock_col + '=', previous_lock_value)
          raise
        end
      end

      # This is patched because we need it to query `lock_version IS NULL`
      # rather than `lock_version = 0` whenever lock_version is NULL.
      def relation_for_destroy
        return super unless locking_enabled?

        column_name = self.class.locking_column
        super.where(self.class.arel_table[column_name].eq(self[column_name]))
      end
    end

    # This is patched because we want `lock_version` default to `NULL`
    # rather than `0`
    class LockingType
      def deserialize(value)
        super
      end

      def serialize(value)
        super
      end
    end
  end
end

# frozen_string_literal: true

class DeduplicateEpicIids < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_epics_on_group_id_and_iid'

  disable_ddl_transaction!

  class Epic < ActiveRecord::Base
  end

  class InternalId < ActiveRecord::Base
    class << self
      def generate_next(subject, scope, usage, init)
        InternalIdGenerator.new(subject, scope, usage, init).generate
      end
    end

    # Increments #last_value and saves the record
    #
    # The operation locks the record and gathers a `ROW SHARE` lock (in PostgreSQL).
    # As such, the increment is atomic and safe to be called concurrently.
    def increment_and_save!
      update_and_save { self.last_value = (last_value || 0) + 1 }
    end

    private

    def update_and_save(&block)
      lock!
      yield
      save!
      last_value
    end
  end

  # See app/models/internal_id
  class InternalIdGenerator
    attr_reader :subject, :scope, :scope_attrs, :usage, :init

    def initialize(subject, scope, usage, init = nil)
      @subject = subject
      @scope = scope
      @usage = usage
      @init = init

      raise ArgumentError, 'Scope is not well-defined, need at least one column for scope (given: 0)' if scope.empty? || usage.to_s != 'epics'
    end

    # Generates next internal id and returns it
    # init: Block that gets called to initialize InternalId record if not present
    #       Make sure to not throw exceptions in the absence of records (if this is expected).
    def generate
      subject.transaction do
        # Create a record in internal_ids if one does not yet exist
        # and increment its last value
        #
        # Note this will acquire a ROW SHARE lock on the InternalId record
        record.increment_and_save!
      end
    end

    def record
      @record ||= (lookup || create_record)
    end

    def lookup
      InternalId.find_by(**scope, usage: usage_value)
    end

    def usage_value
      4 # see Enums::InternalId - this is the value for epics
    end

    # Create InternalId record for (scope, usage) combination, if it doesn't exist
    #
    # We blindly insert without synchronization. If another process
    # was faster in doing this, we'll realize once we hit the unique key constraint
    # violation. We can safely roll-back the nested transaction and perform
    # a lookup instead to retrieve the record.
    def create_record
      raise ArgumentError, 'Cannot initialize without init!' unless init

      instance = subject.is_a?(::Class) ? nil : subject

      subject.transaction(requires_new: true) do
        InternalId.create!(
          **scope,
          usage: usage_value,
          last_value: init.call(instance, scope) || 0
        )
      end
    rescue ActiveRecord::RecordNotUnique
      lookup
    end
  end

  def up
    duplicate_epic_ids = ApplicationRecord.connection.execute('SELECT iid, group_id, COUNT(*) FROM epics GROUP BY iid, group_id HAVING COUNT(*) > 1;')

    duplicate_epic_ids.each do |dup|
      Epic.where(iid: dup['iid'], group_id: dup['group_id']).last(dup['count'] - 1).each do |epic|
        new_iid = InternalId.generate_next(epic,
          { namespace_id: epic.group_id },
          :epics, ->(instance, _) { instance.class.where(group_id: epic.group_id).maximum(:iid) }
        )

        epic.update!(iid: new_iid)
      end
    end

    add_concurrent_index :epics, [:group_id, :iid], unique: true, name: INDEX_NAME
  end

  def down
    # only remove the index, as we do not want to create the duplicates back
    remove_concurrent_index :epics, [:group_id, :iid], name: INDEX_NAME
  end
end

# frozen_string_literal: true

# An InternalId is a strictly monotone sequence of integers
# generated for a given scope and usage.
#
# The monotone sequence may be broken if an ID is explicitly provided
# to `#track_greatest`.
#
# For example, issues use their project to scope internal ids:
# In that sense, scope is "project" and usage is "issues".
# Generated internal ids for an issue are unique per project.
#
# See InternalId#usage enum for available usages.
#
# In order to leverage InternalId for other usages, the idea is to
# * Add `usage` value to enum
# * (Optionally) add columns to `internal_ids` if needed for scope.
class InternalId < ApplicationRecord
  extend Gitlab::Utils::StrongMemoize

  belongs_to :project
  belongs_to :namespace

  enum usage: Enums::InternalId.usage_resources

  validates :usage, presence: true

  scope :filter_by, ->(scope, usage) do
    where(**scope, usage: usage)
  end

  class << self
    def track_greatest(subject, scope, usage, new_value, init)
      build_generator(subject, scope, usage, init).track_greatest(new_value)
    end

    def generate_next(subject, scope, usage, init)
      build_generator(subject, scope, usage, init).generate
    end

    def reset(subject, scope, usage, value)
      build_generator(subject, scope, usage).reset(value)
    end

    # Flushing records is generally safe in a sense that those
    # records are going to be re-created when needed.
    #
    # A filter condition has to be provided to not accidentally flush
    # records for all projects.
    def flush_records!(filter)
      raise ArgumentError, "filter cannot be empty" if filter.blank?

      where(filter).delete_all
    end

    def internal_id_transactions_increment(operation:, usage:)
      self.internal_id_transactions_total.increment(
        operation: operation,
        usage: usage.to_s,
        in_transaction: InternalId.connection.transaction_open?.to_s
      )
    end

    def internal_id_transactions_total
      strong_memoize(:internal_id_transactions_total) do
        name = :gitlab_internal_id_transactions_total
        comment = 'Counts all the internal ids happening within transaction'

        Gitlab::Metrics.counter(name, comment)
      end
    end

    private

    def build_generator(subject, scope, usage, init = nil)
      ImplicitlyLockingInternalIdGenerator.new(subject, scope, usage, init)
    end
  end

  class ImplicitlyLockingInternalIdGenerator
    # Generate next internal id for a given scope and usage.
    #
    # For currently supported usages, see #usage enum.
    #
    # The method implements a locking scheme that has the following properties:
    # 1) Generated sequence of internal ids is unique per (scope and usage)
    # 2) The method is thread-safe and may be used in concurrent threads/processes.
    # 3) The generated sequence is gapless.
    # 4) In the absence of a record in the internal_ids table, one will be created
    #    and last_value will be calculated on the fly.
    #
    # subject: The instance or class we're generating an internal id for.
    # scope: Attributes that define the scope for id generation.
    #        Valid keys are `project/project_id` and `namespace/namespace_id`.
    # usage: Symbol to define the usage of the internal id, see InternalId.usages
    # init: Proc that accepts the subject and the scope and returns Integer|NilClass
    attr_reader :subject, :scope, :scope_attrs, :usage, :init

    RecordAlreadyExists = Class.new(StandardError)

    def initialize(subject, scope, usage, init = nil)
      @subject = subject
      @scope = scope
      @usage = usage
      @init = init

      raise ArgumentError, 'Scope is not well-defined, need at least one column for scope (given: 0)' if scope.empty?

      unless InternalId.usages.has_key?(usage.to_s)
        raise ArgumentError, "Usage '#{usage}' is unknown. Supported values are #{InternalId.usages.keys} from InternalId.usages"
      end
    end

    # Generates next internal id and returns it
    # init: Block that gets called to initialize InternalId record if not present
    #       Make sure to not throw exceptions in the absence of records (if this is expected).
    def generate
      InternalId.internal_id_transactions_increment(operation: :generate, usage: usage)

      next_iid = update_record!(subject, scope, usage, arel_table[:last_value] + 1)

      return next_iid if next_iid

      create_record!(subject, scope, usage, initial_value(subject, scope) + 1)
    rescue RecordAlreadyExists
      retry
    end

    # Reset tries to rewind to `value-1`. This will only succeed,
    # if `value` stored in database is equal to `last_value`.
    # value: The expected last_value to decrement
    def reset(value)
      return false unless value

      InternalId.internal_id_transactions_increment(operation: :reset, usage: usage)

      iid = update_record!(subject, scope.merge(last_value: value), usage, arel_table[:last_value] - 1)
      iid == value - 1
    end

    # Create a record in internal_ids if one does not yet exist
    # and set its new_value if it is higher than the current last_value
    def track_greatest(new_value)
      InternalId.internal_id_transactions_increment(operation: :track_greatest, usage: usage)

      function = Arel::Nodes::NamedFunction.new('GREATEST', [arel_table[:last_value], new_value.to_i])

      next_iid = update_record!(subject, scope, usage, function)
      return next_iid if next_iid

      create_record!(subject, scope, usage, [initial_value(subject, scope), new_value].max)
    rescue RecordAlreadyExists
      retry
    end

    private

    def update_record!(subject, scope, usage, new_value)
      stmt = Arel::UpdateManager.new
      stmt.table(arel_table)
      stmt.set(arel_table[:last_value] => new_value)
      stmt.wheres = InternalId.filter_by(scope, usage).arel.constraints

      InternalId.connection.insert(stmt, 'Update InternalId', 'last_value')
    end

    def create_record!(subject, scope, usage, value)
      scope[:project].save! if scope[:project] && !scope[:project].persisted?
      scope[:namespace].save! if scope[:namespace] && !scope[:namespace].persisted?

      attributes = {
        project_id: scope[:project]&.id || scope[:project_id],
        namespace_id: scope[:namespace]&.id || scope[:namespace_id],
        usage: usage_value,
        last_value: value
      }

      result = InternalId.insert(attributes)

      raise RecordAlreadyExists if result.empty?

      value
    end

    def arel_table
      InternalId.arel_table
    end

    def initial_value(subject, scope)
      raise ArgumentError, 'Cannot initialize without init!' unless init

      # `init` computes the maximum based on actual records. We use the
      # primary to make sure we have up to date results
      Gitlab::Database::LoadBalancing::SessionMap.current(subject.load_balancer).use_primary do
        instance = subject.is_a?(::Class) ? nil : subject

        init.call(instance, scope) || 0
      end
    end

    def usage_value
      @usage_value ||= InternalId.usages[usage.to_s]
    end
  end
end

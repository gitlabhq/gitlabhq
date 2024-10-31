# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  include DisablesSti
  include DatabaseReflection
  include Transactions
  include LegacyBulkInsert
  include CrossDatabaseModification
  include Gitlab::SensitiveAttributes
  include Gitlab::SensitiveSerializableHash
  include ResetOnColumnErrors
  include HasCheckConstraints
  include IgnorableColumns

  self.abstract_class = true

  # We should avoid using pluck https://docs.gitlab.com/ee/development/sql.html#plucking-ids
  # but, if we are going to use it, let's try and limit the number of records
  MAX_PLUCK = 1_000

  alias_method :reset, :reload

  def self.without_order
    reorder(nil)
  end

  def self.id_in(ids)
    where(id: ids)
  end

  def self.primary_key_in(values)
    where(primary_key => values)
  end

  def self.iid_in(iids)
    where(iid: iids)
  end

  def self.id_not_in(ids)
    where.not(id: ids)
  end

  def self.pluck_primary_key
    where(nil).pluck(primary_key)
  end

  def self.safe_ensure_unique(retries: 0)
    transaction(requires_new: true) do # rubocop:disable Performance/ActiveRecordSubtransactions
      yield
    end
  rescue ActiveRecord::RecordNotUnique
    if retries > 0
      retries -= 1
      retry
    end

    false
  end

  def self.safe_find_or_create_by!(*args, &block)
    safe_find_or_create_by(*args, &block).tap do |record|
      raise ActiveRecord::RecordNotFound unless record.present?

      record.validate! unless record.persisted?
    end
  end

  # Start a new transaction with a shorter-than-usual statement timeout. This is
  # currently one third of the default 15-second timeout with a 500ms buffer
  # to allow callers gracefully handling the errors to still complete within
  # the 5s target duration of a low urgency request.
  def self.with_fast_read_statement_timeout(timeout_ms = 4500)
    ::Gitlab::Database::LoadBalancing::SessionMap.current(load_balancer).fallback_to_replicas_for_ambiguous_queries do
      transaction(requires_new: true) do # rubocop:disable Performance/ActiveRecordSubtransactions
        connection.exec_query("SET LOCAL statement_timeout = #{timeout_ms}")

        yield
      end
    end
  end

  def self.safe_find_or_create_by(*args, &block)
    record = find_by(*args)
    return record if record.present?

    # We need to use `all.create` to make this implementation follow `find_or_create_by` which delegates this in
    # https://github.com/rails/rails/blob/v6.1.3.2/activerecord/lib/active_record/querying.rb#L22
    #
    # When calling this method on an association, just calling `self.create` would call `ActiveRecord::Persistence.create`
    # and that skips some code that adds the newly created record to the association.
    transaction(requires_new: true) { all.create(*args, &block) } # rubocop:disable Performance/ActiveRecordSubtransactions
  rescue ActiveRecord::RecordNotUnique
    find_by(*args)
  end

  def create_or_load_association(association_name)
    association(association_name).create unless association(association_name).loaded?
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    association(association_name).reader
  end

  def self.underscore
    @underscore ||= to_s.underscore
  end

  def self.where_exists(query)
    where('EXISTS (?)', query.select(1))
  end

  def self.where_not_exists(query)
    where('NOT EXISTS (?)', query.select(1))
  end

  def self.declarative_enum(enum_mod)
    enum(enum_mod.key => enum_mod.values)
  end

  def self.cached_column_list
    column_names.map { |column_name| arel_table[column_name] }
  end

  def self.default_select_columns
    if ignored_columns.any?
      cached_column_list
    else
      arel_table[Arel.star]
    end
  end

  # This method has been removed in Rails 7.1
  # However, application relies on it in case-when usages with objects wrapped in presenters
  def self.===(object)
    object.is_a?(self)
  end

  def self.nullable_column?(column_name)
    columns.find { |column| column.name == column_name }.null &&
      !not_null_check?(column_name)
  end

  def readable_by?(user)
    Ability.allowed?(user, "read_#{to_ability_name}".to_sym, self)
  end

  def to_ability_name
    model_name.element
  end
end

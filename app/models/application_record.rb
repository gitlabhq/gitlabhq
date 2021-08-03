# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

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
    where(nil).pluck(self.primary_key)
  end

  def self.safe_ensure_unique(retries: 0)
    transaction(requires_new: true) do
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
  # currently one third of the default 15-second timeout
  def self.with_fast_read_statement_timeout(timeout_ms = 5000)
    transaction(requires_new: true) do
      connection.exec_query("SET LOCAL statement_timeout = #{timeout_ms}")

      yield
    end
  end

  def self.safe_find_or_create_by(*args, &block)
    safe_ensure_unique(retries: 1) do
      find_or_create_by(*args, &block)
    end
  end

  def create_or_load_association(association_name)
    association(association_name).create unless association(association_name).loaded?
  rescue ActiveRecord::RecordNotUnique, PG::UniqueViolation
    association(association_name).reader
  end

  def self.underscore
    Gitlab::SafeRequestStore.fetch("model:#{self}:underscore") { self.to_s.underscore }
  end

  def self.where_exists(query)
    where('EXISTS (?)', query.select(1))
  end

  def self.declarative_enum(enum_mod)
    values = enum_mod.definition.transform_values { |v| v[:value] }
    enum(enum_mod.key => values)
  end

  def readable_by?(user)
    Ability.allowed?(user, "read_#{to_ability_name}".to_sym, self)
  end

  def to_ability_name
    model_name.element
  end
end

ApplicationRecord.prepend_mod_with('ApplicationRecordHelpers')

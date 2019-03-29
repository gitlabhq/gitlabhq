# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.id_in(ids)
    where(id: ids)
  end

  def self.id_not_in(ids)
    where.not(id: ids)
  end

  def self.pluck_primary_key
    where(nil).pluck(self.primary_key)
  end

  def self.safe_find_or_create_by!(*args)
    safe_find_or_create_by(*args).tap do |record|
      record.validate! unless record.persisted?
    end
  end

  def self.safe_find_or_create_by(*args)
    transaction(requires_new: true) do
      find_or_create_by(*args)
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end
end

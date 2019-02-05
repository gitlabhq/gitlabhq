# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.id_in(ids)
    where(id: ids)
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

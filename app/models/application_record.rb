# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.id_in(ids)
    where(id: ids)
  end
end

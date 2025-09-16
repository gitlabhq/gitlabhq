# frozen_string_literal: true

class SecApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :sec, reading: :sec } if Gitlab::Database.has_config?(:sec)

  class << self
    def backup_model
      Vulnerabilities::Backup.descendants.find { |descendant| self == descendant.original_model }
    end
  end
end

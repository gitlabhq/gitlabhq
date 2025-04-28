# frozen_string_literal: true

class SecApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :sec, reading: :sec } if Gitlab::Database.has_config?(:sec)
end

# frozen_string_literal: true

module Gitlab
  module Database
    class SecApplicationRecord < ::ApplicationRecord
      self.abstract_class = true

      connects_to database: { writing: :sec, reading: :sec } if Gitlab::Database.has_config?(:sec)
    end
  end
end

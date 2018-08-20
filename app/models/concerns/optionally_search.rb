# frozen_string_literal: true

module OptionallySearch
  extend ActiveSupport::Concern

  module ClassMethods
    def search(*)
      raise(
        NotImplementedError,
        'Your model must implement the "search" class method'
      )
    end

    # Optionally limits a result set to those matching the given search query.
    def optionally_search(query = nil)
      query.present? ? search(query) : all
    end
  end
end

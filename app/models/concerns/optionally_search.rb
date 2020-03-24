# frozen_string_literal: true

module OptionallySearch
  extend ActiveSupport::Concern

  class_methods do
    def search(query, **options)
      raise(
        NotImplementedError,
        'Your model must implement the "search" class method'
      )
    end

    # Optionally limits a result set to those matching the given search query.
    def optionally_search(query = nil, **options)
      query.present? ? search(query, **options) : all
    end
  end
end

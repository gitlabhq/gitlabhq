# frozen_string_literal: true

# Shared scope between Route and RedirectRoute
module RouteModelQuery
  extend ActiveSupport::Concern

  class_methods do
    def find_source_of_path(path, case_sensitive: true)
      scope =
        if case_sensitive
          where(path: path)
        else
          where('LOWER(path) = LOWER(?)', path)
        end

      scope.first&.source
    end
  end
end

# frozen_string_literal: true

module Mutations
  module FindsNamespace
    private

    def find_object(full_path)
      Routable.find_by_full_path(full_path)
    end
  end
end

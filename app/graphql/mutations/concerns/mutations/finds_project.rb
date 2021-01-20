# frozen_string_literal: true

module Mutations
  module FindsProject
    private

    def find_object(full_path)
      Project.find_by_full_path(full_path)
    end
  end
end

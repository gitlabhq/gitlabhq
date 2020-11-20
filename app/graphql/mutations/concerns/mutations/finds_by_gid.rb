# frozen_string_literal: true

module Mutations
  module FindsByGid
    def find_object(id:)
      GitlabSchema.find_by_gid(id)
    end
  end
end

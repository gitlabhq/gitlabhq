# frozen_string_literal: true

module API
  module Entities
    class DiffRefs < Grape::Entity
      expose :base_sha, :head_sha, :start_sha
    end
  end
end

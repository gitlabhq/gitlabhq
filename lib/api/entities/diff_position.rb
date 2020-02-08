# frozen_string_literal: true

module API
  module Entities
    class DiffPosition < Grape::Entity
      expose :base_sha, :start_sha, :head_sha, :old_path, :new_path,
        :position_type
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    class Diff < Grape::Entity
      expose :old_path, :new_path, :a_mode, :b_mode
      expose :new_file?, as: :new_file
      expose :renamed_file?, as: :renamed_file
      expose :deleted_file?, as: :deleted_file
      expose :json_safe_diff, as: :diff
    end
  end
end

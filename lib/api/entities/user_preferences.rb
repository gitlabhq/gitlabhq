# frozen_string_literal: true

module API
  module Entities
    class UserPreferences < Grape::Entity
      expose :id, :user_id, :view_diffs_file_by_file
    end
  end
end

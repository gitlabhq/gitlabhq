# frozen_string_literal: true

module Admin
  module GroupsHelper
    def admin_groups_app_data
      {
        base_path: admin_groups_path
      }.to_json
    end
  end
end

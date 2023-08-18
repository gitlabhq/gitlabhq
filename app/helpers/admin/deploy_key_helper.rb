# frozen_string_literal: true

module Admin
  module DeployKeyHelper
    def admin_deploy_keys_data
      {
        edit_path: edit_admin_deploy_key_path(':id'),
        delete_path: admin_deploy_key_path(':id'),
        create_path: new_admin_deploy_key_path,
        empty_state_svg_path: image_path('illustrations/empty-state/empty-access-token-md.svg')
      }
    end
  end
end

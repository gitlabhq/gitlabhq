# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::DeployKeyHelper do
  describe '#admin_deploy_keys_data' do
    let_it_be(:edit_path) { '/admin/deploy_keys/:id/edit' }
    let_it_be(:delete_path) { '/admin/deploy_keys/:id' }
    let_it_be(:create_path) { '/admin/deploy_keys/new' }
    let_it_be(:empty_state_svg_path) { '/assets/illustrations/empty-state/empty-access-token-md.svg' }

    subject(:result) { helper.admin_deploy_keys_data }

    it 'returns correct hash' do
      expect(helper).to receive(:edit_admin_deploy_key_path).with(':id').and_return(edit_path)
      expect(helper).to receive(:admin_deploy_key_path).with(':id').and_return(delete_path)
      expect(helper).to receive(:new_admin_deploy_key_path).and_return(create_path)
      expect(helper).to receive(:image_path).with('illustrations/empty-state/empty-access-token-md.svg').and_return(empty_state_svg_path)

      expect(result).to eq({
        edit_path: edit_path,
        delete_path: delete_path,
        create_path: create_path,
        empty_state_svg_path: empty_state_svg_path
      })
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployTokensHelper do
  describe '#deploy_token_revoke_button_data' do
    let_it_be(:token) { build(:deploy_token) }
    let_it_be(:project) { build(:project) }
    let_it_be(:revoke_deploy_token_path) { '/foobar/baz/-/deploy_tokens/1/revoke' }

    it 'returns expected hash' do
      expect(helper).to receive(:revoke_deploy_token_path).with(project, token).and_return(revoke_deploy_token_path)

      expect(helper.deploy_token_revoke_button_data(token: token, group_or_project: project)).to match({
        token: token.to_json(only: [:id, :name]),
        revoke_path: revoke_deploy_token_path
      })
    end
  end
end

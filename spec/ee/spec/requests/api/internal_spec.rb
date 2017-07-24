require 'spec_helper'

describe API::Internal do # rubocop:disable RSpec/FilePath
  let(:project) { create(:project, :repository) }
  let(:secret_token) { Gitlab::Shell.secret_token }

  describe "POST /internal/allowed", :clean_gitlab_redis_shared_state do
    context 'Geo Node' do
      let(:geo_node) { create(:geo_node) }

      it 'recognizes the Geo Node' do
        post(
          api("/internal/allowed"),
          key_id: geo_node.geo_node_key.id,
          project: project.repository.path_to_repo,
          action: 'git-upload-pack',
          secret_token: secret_token,
          protocol: 'ssh')

        expect(response.status).to eq(200)
        expect(json_response['geo_node']).to be(true)
      end
    end

    context 'user' do
      let(:user) { create(:user) }
      let(:key) { create(:key, user: user) }

      before do
        project.team << [user, :developer]
      end

      it 'does not recognize key as a Geo Node' do
        post(
          api("/internal/allowed"),
          key_id: key.id,
          project: project.repository.path_to_repo,
          action: 'git-upload-pack',
          secret_token: secret_token,
          protocol: 'ssh')

        expect(response.status).to eq(200)
        expect(json_response['geo_node']).to be(false)
      end
    end
  end
end

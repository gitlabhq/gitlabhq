require 'spec_helper'

describe Projects::DeployKeysController do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'GET index' do
    let(:params) do
      { namespace_id: project.namespace, project_id: project }
    end

    context 'when html requested' do
      it 'redirects to blob' do
        get :index, params

        expect(response).to redirect_to(namespace_project_settings_repository_path(params))
      end
    end

    context 'when json requested' do
      let(:project2) { create(:project, :internal)}
      let(:project_private) { create(:project, :private)}

      let(:deploy_key_internal) do
        create(:deploy_key, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQCdMHEHyhRjbhEZVddFn6lTWdgEy5Q6Bz4nwGB76xWZI5YT/1WJOMEW+sL5zYd31kk7sd3FJ5L9ft8zWMWrr/iWXQikC2cqZK24H1xy+ZUmrRuJD4qGAaIVoyyzBL+avL+lF8J5lg6YSw8gwJY/lX64/vnJHUlWw2n5BF8IFOWhiw== dummy@gitlab.com')
      end
      let(:deploy_key_actual) do
        create(:deploy_key, key: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDNd/UJWhPrpb+b/G5oL109y57yKuCxE+WUGJGYaj7WQKsYRJmLYh1mgjrl+KVyfsWpq4ylOxIfFSnN9xBBFN8mlb0Fma5DC7YsSsibJr3MZ19ZNBprwNcdogET7aW9I0In7Wu5f2KqI6e5W/spJHCy4JVxzVMUvk6Myab0LnJ2iQ== dummy@gitlab.com')
      end
      let!(:deploy_key_public) { create(:deploy_key, public: true) }

      let!(:deploy_keys_project_internal) do
        create(:deploy_keys_project, project: project2, deploy_key: deploy_key_internal)
      end

      let!(:deploy_keys_actual_project) do
        create(:deploy_keys_project, project: project, deploy_key: deploy_key_actual)
      end

      let!(:deploy_keys_project_private) do
        create(:deploy_keys_project, project: project_private, deploy_key: create(:another_deploy_key))
      end

      before do
        project2.add_developer(user)
      end

      it 'returns json in a correct format' do
        get :index, params.merge(format: :json)

        json = JSON.parse(response.body)

        expect(json.keys).to match_array(%w(enabled_keys available_project_keys public_keys))
        expect(json['enabled_keys'].count).to eq(1)
        expect(json['available_project_keys'].count).to eq(1)
        expect(json['public_keys'].count).to eq(1)
      end
    end
  end
end

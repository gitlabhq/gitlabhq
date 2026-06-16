# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DeployKeys, '(JavaScript fixtures)', type: :request, feature_category: :continuous_delivery do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:admin, freeze: false) { create(:admin) }
  let_it_be(:path, freeze: false) { "/deploy_keys" }
  let_it_be(:project, freeze: false) { create(:project) }
  let_it_be(:project2, freeze: false) { create(:project) }
  let_it_be(:deploy_key, freeze: false) { create(:deploy_key, public: true) }
  let_it_be(:deploy_key2, freeze: false) { create(:deploy_key, public: true) }
  let_it_be(:deploy_key_without_fingerprint, freeze: false) { create(:deploy_key, :without_md5_fingerprint, public: true) }
  let_it_be(:deploy_keys_project, freeze: false) { create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key) }
  let_it_be(:deploy_keys_project2, freeze: false) { create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key) }
  let_it_be(:deploy_keys_project3, freeze: false) { create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key2) }
  let_it_be(:deploy_keys_project4, freeze: false) { create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key2) }

  it_behaves_like 'GET request permissions for admin mode'

  it 'api/deploy_keys/index.json' do
    get api("/deploy_keys", admin, admin_mode: true)

    expect(response).to be_successful
  end
end

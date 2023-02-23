# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::DeployKeys, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:path) { "/deploy_keys" }
  let_it_be(:project) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:deploy_key) { create(:deploy_key, public: true) }
  let_it_be(:deploy_key2) { create(:deploy_key, public: true) }
  let_it_be(:deploy_key_without_fingerprint) { create(:deploy_key, :without_md5_fingerprint, public: true) }
  let_it_be(:deploy_keys_project) { create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key) }
  let_it_be(:deploy_keys_project2) { create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key) }
  let_it_be(:deploy_keys_project3) { create(:deploy_keys_project, :write_access, project: project, deploy_key: deploy_key2) }
  let_it_be(:deploy_keys_project4) { create(:deploy_keys_project, :write_access, project: project2, deploy_key: deploy_key2) }

  it_behaves_like 'GET request permissions for admin mode'

  it 'api/deploy_keys/index.json' do
    get api("/deploy_keys", admin, admin_mode: true)

    expect(response).to be_successful
  end
end

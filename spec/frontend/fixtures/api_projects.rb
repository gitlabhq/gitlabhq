# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Projects, '(JavaScript fixtures)', type: :request do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:namespace, name: 'gitlab-test') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'lorem-ipsum') }
  let_it_be(:project_empty) { create(:project_empty_repo, namespace: namespace, path: 'lorem-ipsum-empty') }
  let_it_be(:user) { project.owner }
  let_it_be(:personal_projects) { create_list(:project, 3, namespace: user.namespace, topics: create_list(:topic, 5)) }

  it 'api/projects/get.json' do
    get api("/projects/#{project.id}", user)

    expect(response).to be_successful
  end

  it 'api/projects/get_empty.json' do
    get api("/projects/#{project_empty.id}", user)

    expect(response).to be_successful
  end

  it 'api/projects/branches/get.json' do
    get api("/projects/#{project.id}/repository/branches/#{project.default_branch}", user)

    expect(response).to be_successful
  end

  it 'api/users/projects/get.json' do
    get api("/users/#{user.id}/projects", user)

    expect(response).to be_successful
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlobController, '(JavaScript fixtures)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:namespace) { create(:namespace, name: 'frontend-fixtures') }
  let(:project) { create(:project, :repository, namespace: namespace, path: 'branches-project') }
  let(:user) { project.first_owner }

  render_views

  before do
    sign_in(user)
    allow(SecureRandom).to receive(:hex).and_return('securerandomhex:thereisnospoon')
  end

  after do
    remove_repository(project)
  end

  it 'blob/show.html' do
    get(:show, params: {
      namespace_id: project.namespace,
      project_id: project,
      id: 'add-ipython-files/files/ipython/basic.ipynb'
    })

    expect(response).to be_successful
  end

  it 'blob/show_readme.html' do
    get(:show, params: {
      namespace_id: project.namespace,
      project_id: project,
      id: "#{project.default_branch}/README.md"
    })

    expect(response).to be_successful
  end
end

require 'spec_helper'

describe Projects::GraphsController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  describe 'GET languages' do
    it "redirects_to action charts" do
      get(:commits, namespace_id: project.namespace.path, project_id: project.path, id: 'master')

      expect(response).to redirect_to action: :charts
    end
  end

  describe 'GET commits' do
    it "redirects_to action charts" do
      get(:commits, namespace_id: project.namespace.path, project_id: project.path, id: 'master')

      expect(response).to redirect_to action: :charts
    end
  end
end

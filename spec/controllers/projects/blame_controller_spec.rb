require 'spec_helper'

describe Projects::BlameController do
  let(:project) { create(:project) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.team << [user, :master]
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    render_views

    before do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project.to_param,
          id: id)
    end

    context "valid file" do
      let(:id) { 'master/files/ruby/popen.rb' }
      it { is_expected.to respond_with(:success) }
    end
  end
end

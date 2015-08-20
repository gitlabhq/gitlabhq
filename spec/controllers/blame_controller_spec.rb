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

      it 'groups blames properly' do
        blame = assigns(:blame)
        # Sanity check a few items
        expect(blame.count).to eq(18)
        expect(blame[0][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
        expect(blame[0][:lines]).to eq(["require 'fileutils'", "require 'open3'", ""])

        expect(blame[1][:commit].sha).to eq('874797c3a73b60d2187ed6e2fcabd289ff75171e')
        expect(blame[1][:lines]).to eq(["module Popen", "  extend self"])

        expect(blame[-1][:commit].sha).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
        expect(blame[-1][:lines]).to eq(["  end", "end"])
      end
    end
  end
end

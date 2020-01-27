# frozen_string_literal: true

require 'spec_helper'

describe Projects::BlameController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.add_maintainer(user)
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    render_views

    before do
      get(:show,
          params: {
            namespace_id: project.namespace,
            project_id: project,
            id: id
          })
    end

    context "valid branch, valid file" do
      let(:id) { 'master/files/ruby/popen.rb' }

      it { is_expected.to respond_with(:success) }
    end

    context "valid branch, invalid file" do
      let(:id) { 'master/files/ruby/invalid-path.rb' }

      it 'redirects' do
        expect(subject)
            .to redirect_to("/#{project.full_path}/-/tree/master")
      end
    end

    context "invalid branch, valid file" do
      let(:id) { 'invalid-branch/files/ruby/missing_file.rb'}

      it { is_expected.to respond_with(:not_found) }
    end
  end
end

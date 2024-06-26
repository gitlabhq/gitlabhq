# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlameController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user) }

  before do
    sign_in(user)

    project.add_maintainer(user)
    controller.instance_variable_set(:@project, project)
  end

  shared_examples 'blame_response' do
    context 'valid branch, valid file' do
      let(:id) { 'master/files/ruby/popen.rb' }

      it { is_expected.to respond_with(:success) }
    end

    context 'valid branch, invalid file' do
      let(:id) { 'master/files/ruby/invalid-path.rb' }

      it 'redirects' do
        expect(subject).to redirect_to("/#{project.full_path}/-/tree/master")
      end
    end

    context 'valid branch, binary file' do
      let(:id) { 'master/files/images/logo-black.png' }

      it 'redirects' do
        expect(subject).to redirect_to("/#{project.full_path}/-/blob/master/files/images/logo-black.png")
      end
    end

    context 'invalid branch, valid file' do
      let(:id) { 'invalid-branch/files/ruby/missing_file.rb' }

      it { is_expected.to respond_with(:not_found) }
    end

    context 'when ref includes a newline' do
      let(:id) { "\n" }

      it 'returns 404' do
        is_expected.to respond_with(:not_found)
      end
    end
  end

  describe 'GET show' do
    render_views

    before do
      get :show, params: { namespace_id: project.namespace, project_id: project, id: id }
    end

    it_behaves_like 'blame_response'
  end

  describe 'GET page' do
    render_views

    before do
      get :page, params: { namespace_id: project.namespace, project_id: project, id: id }
    end

    it_behaves_like 'blame_response'
  end

  describe 'GET streaming' do
    render_views

    before do
      get :streaming, params: { namespace_id: project.namespace, project_id: project, id: id }
    end

    it_behaves_like 'blame_response'
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::BlameController, feature_category: :source_code_management do
  include RepoHelpers
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

    let(:params) { { namespace_id: project.namespace, project_id: project, id: id, ignore_revs: ignore_revs } }
    let(:ignore_revs) { nil }
    let(:request) { get :show, params: params }

    context 'when ignore_revs is nil' do
      before do
        request
      end

      it_behaves_like 'blame_response'
    end

    context 'when ignore_revs is true' do
      let(:ignore_revs) { true }
      let(:id) { 'master/files/ruby/popen.rb' }

      shared_examples_for 'redirecting ignore rev with flash' do |flash_message|
        context 'and there are other params' do
          let(:params) { super().merge(ref_type: 'heads') }

          it 'redirects with those params' do
            request

            expect(controller).to redirect_to("/#{project.full_path}/-/blame/#{id}?ref_type=heads")
          end
        end

        it 'redirects with flash' do
          request

          expect(controller).to redirect_to("/#{project.full_path}/-/blame/#{id}")
          expect(flash[:notice]).to eq(flash_message)
        end
      end

      context 'and there is no ignore revs file' do
        it_behaves_like 'redirecting ignore rev with flash', '.git-blame-ignore-revs is not a file'
      end

      context 'and there is an ignore revs file' do
        let(:project_files) do
          { Gitlab::Blame::IGNORE_REVS_FILE_NAME => file_content }
        end

        around do |example|
          create_and_delete_files(project, project_files) do
            example.run
          end
        end

        context 'and it is malformed' do
          let(:file_content) { 'malformed content' }

          it_behaves_like 'redirecting ignore rev with flash', 'Malformed .git-blame-ignore-revs'
        end

        context 'and it contains commit ids' do
          let(:file_content) { project.commit.id }

          it 'responds successfully' do
            request
            is_expected.to respond_with(:success)
          end
        end
      end
    end
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

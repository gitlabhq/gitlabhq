# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TreeController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  before do
    sign_in(user)

    project.add_maintainer(user)
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    let(:params) do
      {
        namespace_id: project.namespace.to_param, project_id: project, id: id, ref_type: ref_type
      }
    end

    let(:request) { get :show, params: params }

    let(:ref_type) { nil }

    # Make sure any errors accessing the tree in our views bubble up to this spec
    render_views

    include_context 'with ambiguous refs for controllers'

    describe '#set_is_ambiguous_ref before action' do
      before do
        request
      end

      context 'when ref requested is ambiguous with no ref type' do
        let(:id) { 'ambiguous_ref' }

        it_behaves_like '#set_is_ambiguous_ref when ref is ambiguous'
      end

      context 'when ref requested is not ambiguous' do
        let(:id) { 'master' }

        it_behaves_like '#set_is_ambiguous_ref when ref is not ambiguous'
      end
    end

    context "valid branch, no path" do
      let(:id) { 'flatten-dir' }

      it 'checks for tree without ref_type' do
        allow(project.repository).to receive(:tree).and_call_original
        expect(project.repository).to receive(:tree).with(RepoHelpers.another_sample_commit.id, '').and_call_original
        request
      end

      it 'responds with success' do
        request
        expect(response).to be_ok
      end
    end

    context "valid branch, valid path" do
      let(:id) { 'master/encoding/' }

      it 'responds with success' do
        request
        expect(response).to be_ok
      end
    end

    context "valid branch, invalid path" do
      let(:id) { 'master/invalid-path/' }

      it 'redirects' do
        request
        expect(subject)
            .to redirect_to("/#{project.full_path}/-/tree/master")
      end
    end

    context "invalid branch, valid path" do
      let(:id) { 'invalid-branch/encoding/' }

      it 'responds with not_found' do
        request
        expect(subject).to respond_with(:not_found)
      end
    end

    context 'when default branch was renamed' do
      let_it_be_with_reload(:project) { create(:project, :repository, previous_default_branch: 'old-default-branch') }

      context "and the file is valid" do
        let(:id) { 'old-default-branch/encoding/' }

        it 'redirects' do
          request
          expect(subject).to redirect_to("/#{project.full_path}/-/tree/#{project.default_branch}/encoding/")
        end
      end

      context "and the file is invalid" do
        let(:id) { 'old-default-branch/invalid-path/' }

        it 'redirects' do
          request
          expect(subject).to redirect_to("/#{project.full_path}/-/tree/#{project.default_branch}/invalid-path/")
        end
      end
    end

    context "valid empty branch, invalid path" do
      let(:id) { 'empty-branch/invalid-path/' }

      it 'redirects' do
        request
        expect(subject).to redirect_to("/#{project.full_path}/-/tree/empty-branch")
      end
    end

    context "valid empty branch" do
      let(:id) { 'empty-branch' }

      it 'responds with success' do
        request
        expect(response).to be_ok
      end
    end

    context "invalid SHA commit ID" do
      let(:id) { 'ff39438/.gitignore' }

      it 'responds with not_found' do
        request
        expect(subject).to respond_with(:not_found)
      end
    end

    context "valid SHA commit ID" do
      let(:id) { '6d39438' }

      it 'responds with success' do
        request
        expect(response).to be_ok
      end

      context 'and there is a tag with the same name' do
        before do
          project.repository.add_tag(project.creator, id, RepoHelpers.sample_commit.id)
        end

        it 'responds with success' do
          request

          # This uses the tag
          # TODO: Should we redirect in this case?
          expect(response).to be_ok
        end
      end
    end

    context "valid SHA commit ID with path" do
      let(:id) { '6d39438/.gitignore' }

      it 'responds with found' do
        request
        expect(response).to have_gitlab_http_status(:found)
      end
    end
  end

  describe 'GET show with whitespace in ref' do
    render_views

    let(:id) { "this ref/api/responses" }

    it 'does not call make a Gitaly request' do
      allow(::Gitlab::GitalyClient).to receive(:call).and_call_original
      expect(::Gitlab::GitalyClient).not_to receive(:call).with(anything, :commit_service, :find_commit, anything, anything)

      get :show, params: {
        namespace_id: project.namespace.to_param, project_id: project, id: id
      }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET show with blob path' do
    render_views

    before do
      get :show, params: {
        namespace_id: project.namespace.to_param, project_id: project, id: id, ref_type: 'heads'
      }
    end

    context 'redirect to blob' do
      let(:id) { 'master/README.md' }

      it 'redirects' do
        redirect_url = "/#{project.full_path}/-/blob/master/README.md?ref_type=heads"
        expect(subject).to redirect_to(redirect_url)
      end
    end
  end

  describe '#create_dir' do
    subject(:create_dir) { post :create_dir, params: params }

    let(:create_merge_request) { nil }
    let(:params) do
      {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master',
        dir_name: path,
        branch_name: branch_name,
        commit_message: 'Test commit message',
        create_merge_request: create_merge_request
      }
    end

    render_views

    context 'successful creation' do
      let(:path) { 'files/new_dir' }
      let(:branch_name) { "main-test-#{SecureRandom.hex}" }

      context 'when not creating a new MR' do
        let(:create_merge_request) { 'false' }

        it 'redirects to the new directory' do
          expect(create_dir)
              .to redirect_to("/#{project.full_path}/-/tree/#{branch_name}/#{path}")
          expect(flash[:notice]).to eq('The directory has been successfully created.')
        end
      end

      context 'when creating a new MR' do
        shared_examples 'a new MR from branch redirection' do
          it 'redirects to the new MR page' do
            expect(create_dir)
                .to redirect_to("/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=#{branch_name}&merge_request%5Btarget_branch%5D=master&merge_request%5Btarget_project_id%5D=#{project.id}")
            expect(flash[:notice]).to eq('The directory has been successfully created. You can now submit a merge request to get this change into the original branch.')
          end
        end

        context "and the passed create_merge_request value is true" do
          it_behaves_like 'a new MR from branch redirection' do
            let(:create_merge_request) { true }
          end
        end

        context "and the passed create_merge_request value is 'true'" do
          it_behaves_like 'a new MR from branch redirection' do
            let(:create_merge_request) { 'true' }
          end
        end

        context "and the passed create_merge_request value is '1'" do
          it_behaves_like 'a new MR from branch redirection' do
            let(:create_merge_request) { '1' }
          end
        end

        context "and the passed create_merge_request value is 1" do
          it_behaves_like 'a new MR from branch redirection' do
            let(:create_merge_request) { 1 }
          end
        end
      end
    end

    context 'unsuccessful creation' do
      let(:path) { 'README.md' }
      let(:branch_name) { 'master' }

      it 'does not allow overwriting of existing files' do
        expect(create_dir)
            .to redirect_to("/#{project.full_path}/-/tree/master")
        expect(flash[:alert]).to eq('A file with this name already exists')
      end

      [:branch_name, :dir_name, :commit_message].each do |required_param|
        context "when #{required_param} is missing" do
          let(:params) { super().except(required_param) }

          it 'raises a missing parameter exception' do
            expect { create_dir }.to raise_error(ActionController::ParameterMissing)
          end
        end

        context "when #{required_param} is empty" do
          let(:params) { super().merge(required_param => nil) }

          it 'raises a missing parameter exception' do
            expect { create_dir }.to raise_error(ActionController::ParameterMissing)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TreeController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:redirect_with_ref_type) { true }

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

    before do
      expect(::Gitlab::GitalyClient).to receive(:allow_ref_name_caching).and_call_original
      project.repository.add_tag(project.creator, 'ambiguous_ref', RepoHelpers.sample_commit.id)
      project.repository.add_branch(project.creator, 'ambiguous_ref', RepoHelpers.another_sample_commit.id)

      stub_feature_flags(redirect_with_ref_type: redirect_with_ref_type)
    end

    after do
      project.repository.rm_tag(project.creator, 'ambiguous_ref')
      project.repository.rm_branch(project.creator, 'ambiguous_ref')
    end

    context 'when the redirect_with_ref_type flag is disabled' do
      let(:redirect_with_ref_type) { false }

      context 'when there is a ref and tag with the same name' do
        let(:id) { 'ambiguous_ref' }
        let(:params) { { namespace_id: project.namespace, project_id: project, id: id, ref_type: ref_type } }

        context 'and explicitly requesting a branch' do
          let(:ref_type) { 'heads' }

          it 'redirects to blob#show with sha for the branch' do
            request
            expect(response).to redirect_to(project_tree_path(project, RepoHelpers.another_sample_commit.id))
          end
        end

        context 'and explicitly requesting a tag' do
          let(:ref_type) { 'tags' }

          it 'responds with success' do
            request
            expect(response).to be_ok
          end
        end
      end
    end

    describe 'delegating to ExtractsRef::RequestedRef' do
      context 'when there is a ref and tag with the same name' do
        let(:id) { 'ambiguous_ref' }
        let(:params) { { namespace_id: project.namespace, project_id: project, id: id, ref_type: ref_type } }

        let(:requested_ref_double) { ExtractsRef::RequestedRef.new(project.repository, ref_type: ref_type, ref: id) }

        before do
          allow(ExtractsRef::RequestedRef).to receive(:new).with(kind_of(Repository), ref_type: ref_type, ref: id).and_return(requested_ref_double)
        end

        context 'and not specifying a ref_type' do
          it 'finds the tags and redirects' do
            expect(requested_ref_double).to receive(:find).and_call_original
            request
            expect(subject).to redirect_to("/#{project.full_path}/-/tree/#{id}/?ref_type=tags")
          end
        end

        context 'and explicitly requesting a branch' do
          let(:ref_type) { 'heads' }

          it 'checks for tree with ref_type' do
            allow(project.repository).to receive(:tree).and_call_original
            expect(project.repository).to receive(:tree).with(id, '', ref_type: 'heads').and_call_original
            request
          end

          it 'finds the branch' do
            expect(requested_ref_double).not_to receive(:find)

            request
            expect(response).to be_ok
          end
        end

        context 'and explicitly requesting a tag' do
          let(:ref_type) { 'tags' }

          it 'checks for tree with ref_type' do
            allow(project.repository).to receive(:tree).and_call_original
            expect(project.repository).to receive(:tree).with(id, '', ref_type: 'tags').and_call_original
            request
          end

          it 'finds the tag' do
            expect(requested_ref_double).not_to receive(:find)
            request
            expect(response).to be_ok
          end
        end
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
    render_views

    before do
      post :create_dir, params: {
        namespace_id: project.namespace.to_param,
        project_id: project,
        id: 'master',
        dir_name: path,
        branch_name: branch_name,
        commit_message: 'Test commit message'
      }
    end

    context 'successful creation' do
      let(:path) { 'files/new_dir' }
      let(:branch_name) { 'master-test' }

      it 'redirects to the new directory' do
        expect(subject)
            .to redirect_to("/#{project.full_path}/-/tree/#{branch_name}/#{path}")
        expect(flash[:notice]).to eq('The directory has been successfully created.')
      end
    end

    context 'unsuccessful creation' do
      let(:path) { 'README.md' }
      let(:branch_name) { 'master' }

      it 'does not allow overwriting of existing files' do
        expect(subject)
            .to redirect_to("/#{project.full_path}/-/tree/master")
        expect(flash[:alert]).to eq('A file with this name already exists')
      end
    end
  end
end

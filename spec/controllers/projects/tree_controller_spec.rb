require 'spec_helper'

describe Projects::TreeController do
  let(:project) { create(:project, :repository) }
  let(:user)    { create(:user) }

  before do
    sign_in(user)

    project.add_master(user)
    controller.instance_variable_set(:@project, project)
  end

  describe "GET show" do
    # Make sure any errors accessing the tree in our views bubble up to this spec
    render_views

    before do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id)
    end

    context "valid branch, no path" do
      let(:id) { 'master' }
      it { is_expected.to respond_with(:success) }
    end

    context "valid branch, valid path" do
      let(:id) { 'master/encoding/' }
      it { is_expected.to respond_with(:success) }
    end

    context "valid branch, invalid path" do
      let(:id) { 'master/invalid-path/' }
      it { is_expected.to respond_with(:not_found) }
    end

    context "invalid branch, valid path" do
      let(:id) { 'invalid-branch/encoding/' }
      it { is_expected.to respond_with(:not_found) }
    end

    context "valid empty branch, invalid path" do
      let(:id) { 'empty-branch/invalid-path/' }
      it { is_expected.to respond_with(:not_found) }
    end

    context "valid empty branch" do
      let(:id) { 'empty-branch' }
      it { is_expected.to respond_with(:success) }
    end

    context "invalid SHA commit ID" do
      let(:id) { 'ff39438/.gitignore' }
      it { is_expected.to respond_with(:not_found) }
    end

    context "valid SHA commit ID" do
      let(:id) { '6d39438' }
      it { is_expected.to respond_with(:success) }
    end

    context "valid SHA commit ID with path" do
      let(:id) { '6d39438/.gitignore' }
      it { expect(response).to have_gitlab_http_status(302) }
    end
  end

  describe 'GET show with blob path' do
    render_views

    before do
      get(:show,
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: id)
    end

    context 'redirect to blob' do
      let(:id) { 'master/README.md' }
      it 'redirects' do
        redirect_url = "/#{project.full_path}/blob/master/README.md"
        expect(subject)
          .to redirect_to(redirect_url)
      end
    end
  end

  describe '#create_dir' do
    render_views

    before do
      post(:create_dir,
           namespace_id: project.namespace.to_param,
           project_id: project,
           id: 'master',
           dir_name: path,
           branch_name: branch_name,
           commit_message: 'Test commit message')
    end

    context 'successful creation' do
      let(:path) { 'files/new_dir'}
      let(:branch_name) { 'master-test'}

      it 'redirects to the new directory' do
        expect(subject)
            .to redirect_to("/#{project.full_path}/tree/#{branch_name}/#{path}")
        expect(flash[:notice]).to eq('The directory has been successfully created.')
      end
    end

    context 'unsuccessful creation' do
      let(:path) { 'README.md' }
      let(:branch_name) { 'master'}

      it 'does not allow overwriting of existing files' do
        expect(subject)
            .to redirect_to("/#{project.full_path}/tree/master")
        expect(flash[:alert]).to eq('A file with this name already exists')
      end
    end
  end
end

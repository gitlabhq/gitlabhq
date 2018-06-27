require('spec_helper')

describe Projects::ProtectedBranchesController do
  let(:project) { create(:project, :repository) }
  let(:protected_branch) { create(:protected_branch, project: project) }
  let(:project_params) { { namespace_id: project.namespace.to_param, project_id: project } }
  let(:base_params) { project_params.merge(id: protected_branch.id) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
  end

  describe "GET #index" do
    let(:project) { create(:project_empty_repo, :public) }

    it "redirects empty repo to projects page" do
      get(:index, namespace_id: project.namespace.to_param, project_id: project)
    end
  end

  describe "POST #create" do
    let(:master_access_level) { [{ access_level: Gitlab::Access::MASTER }] }
    let(:access_level_params) do
      { merge_access_levels_attributes: master_access_level,
        push_access_levels_attributes: master_access_level }
    end
    let(:create_params) { attributes_for(:protected_branch).merge(access_level_params) }

    before do
      sign_in(user)
    end

    it 'creates the protected branch rule' do
      expect do
        post(:create, project_params.merge(protected_branch: create_params))
      end.to change(ProtectedBranch, :count).by(1)
    end

    context 'when a policy restricts rule deletion' do
      before do
        policy = instance_double(ProtectedBranchPolicy, can?: false)
        allow(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents creation of the protected branch rule" do
        post(:create, project_params.merge(protected_branch: create_params))

        expect(ProtectedBranch.count).to eq 0
      end
    end
  end

  describe "PUT #update" do
    let(:update_params) { { name: 'new_name' } }

    before do
      sign_in(user)
    end

    it 'updates the protected branch rule' do
      put(:update, base_params.merge(protected_branch: update_params))

      expect(protected_branch.reload.name).to eq('new_name')
      expect(json_response["name"]).to eq('new_name')
    end

    context 'when a policy restricts rule deletion' do
      before do
        policy = instance_double(ProtectedBranchPolicy, can?: false)
        allow(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents update of the protected branch rule" do
        old_name = protected_branch.name

        put(:update, base_params.merge(protected_branch: update_params))

        expect(protected_branch.reload.name).to eq(old_name)
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      sign_in(user)
    end

    it "deletes the protected branch rule" do
      delete(:destroy, base_params)

      expect { ProtectedBranch.find(protected_branch.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when a policy restricts rule deletion' do
      before do
        policy = instance_double(ProtectedBranchPolicy, can?: false)
        allow(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents deletion of the protected branch rule" do
        delete(:destroy, base_params)

        expect(response.status).to eq(403)
      end
    end
  end
end

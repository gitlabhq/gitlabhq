# frozen_string_literal: true

require('spec_helper')

RSpec.describe Projects::ProtectedBranchesController do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be_with_reload(:empty_project) { create(:project, :empty_repo) }
  let_it_be(:maintainer) { create(:user, maintainer_of: [project, empty_project]) }

  let(:protected_branch) { create(:protected_branch, project: project) }
  let(:project_params) { { namespace_id: project.namespace.to_param, project_id: project } }
  let(:base_params) { project_params.merge(id: protected_branch.id) }
  let(:user) { maintainer }

  before do
    sign_in(user)
  end

  describe "GET #index" do
    it 'redirects to repository settings' do
      get(:index, params: { namespace_id: empty_project.namespace.to_param, project_id: empty_project })

      expect(response).to redirect_to(project_settings_repository_path(empty_project))
    end
  end

  describe "POST #create" do
    let(:maintainer_access_level) { [{ access_level: Gitlab::Access::MAINTAINER }] }
    let(:access_level_params) do
      { merge_access_levels_attributes: maintainer_access_level,
        push_access_levels_attributes: maintainer_access_level }
    end

    let(:create_params) { attributes_for(:protected_branch).merge(access_level_params) }

    describe "created successfully" do
      using RSpec::Parameterized::TableSyntax

      let(:protected_branch) { create(:protected_branch, project: ref_project) }
      let(:project_params) { { namespace_id: ref_project.namespace.to_param, project_id: ref_project } }

      subject { post(:create, params: project_params.merge(protected_branch: create_params), format: format) }

      where(:format, :ref_project, :response_status) do
        :html          | ref(:project)              | :found
        :html          | ref(:empty_project)        | :found
        :json          | ref(:project)              | :ok
        :json          | ref(:empty_project)        | :ok
      end

      with_them do
        it 'creates a protected branch' do
          expect { subject }.to change(ProtectedBranch, :count).by(1)
          expect(response).to have_gitlab_http_status(response_status)
        end
      end
    end

    context 'when a policy restricts rule creation' do
      it "prevents creation of the protected branch rule" do
        disallow(:create_protected_branch, an_instance_of(ProtectedBranch))

        post(:create, params: project_params.merge(protected_branch: create_params))

        expect(ProtectedBranch.count).to eq 0
      end
    end
  end

  describe "PUT #update" do
    let(:update_params) { { name: 'new_name' } }

    it 'updates the protected branch rule' do
      put(:update, params: base_params.merge(protected_branch: update_params))

      expect(protected_branch.reload.name).to eq('new_name')
      expect(json_response["name"]).to eq('new_name')
    end

    context 'when repository is empty' do
      let(:project) { empty_project }

      it 'updates the protected branch rule' do
        put(:update, params: base_params.merge(protected_branch: update_params))

        expect(protected_branch.reload.name).to eq('new_name')
        expect(json_response["name"]).to eq('new_name')
      end
    end

    context 'when a policy restricts rule update' do
      it "prevents update of the protected branch rule" do
        disallow(:update_protected_branch, protected_branch)

        old_name = protected_branch.name

        put(:update, params: base_params.merge(protected_branch: update_params))

        expect(protected_branch.reload.name).to eq(old_name)
      end
    end
  end

  describe "DELETE #destroy" do
    it "deletes the protected branch rule" do
      delete(:destroy, params: base_params)

      expect { ProtectedBranch.find(protected_branch.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when repository is empty' do
      let(:project) { empty_project }

      it 'deletes the protected branch rule' do
        delete(:destroy, params: base_params)

        expect { ProtectedBranch.find(protected_branch.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when a policy restricts rule deletion' do
      it "prevents deletion of the protected branch rule" do
        disallow(:destroy_protected_branch, protected_branch)

        delete(:destroy, params: base_params)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  def disallow(ability, protected_branch)
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?).with(user, ability, protected_branch).and_return(false)
  end
end

require('spec_helper')

describe Projects::ProjectMembersController do
  let(:project) { create(:project) }
  let(:another_project) { create(:project, :private) }
  let(:user) { create(:user) }
  let(:member) { create(:user) }

  before do
    project.team << [user, :master]
    another_project.team << [member, :guest]
    sign_in(user)
  end

  describe '#apply_import' do
    shared_context 'import applied' do
      before do
        post(:apply_import, namespace_id: project.namespace.to_param,
                            project_id: project.to_param,
                            source_project_id: another_project.id)
      end
    end

    context 'when user can access source project members' do
      before { another_project.team << [user, :guest] }
      include_context 'import applied'

      it 'imports source project members' do
        expect(project.team_members).to include member
        expect(response).to set_flash.to 'Successfully imported'
        expect(response).to redirect_to(
          namespace_project_project_members_path(project.namespace, project)
        )
      end
    end

    context 'when user is not member of a source project' do
      include_context 'import applied'

      it 'does not import team members' do
        expect(project.team_members).to_not include member
      end

      it 'responds with not found' do
        expect(response.status).to eq 404
      end
    end
  end

  describe '#index' do
    let(:project) { create(:project, :private) }

    context 'when user is member' do
      let(:member) { create(:user) }

      before do
        project.team << [member, :guest]
        sign_in(member)
        get :index, namespace_id: project.namespace.to_param, project_id: project.to_param
      end

      it { expect(response.status).to eq(200) }
    end
  end
end

require 'spec_helper'

describe Projects::ImportsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  before do
    sign_in(user)
    project.add_master(user)
  end

  context 'POST #create' do
    context 'mirror user is not the current user' do
      it 'should only assign the current user' do
        allow_any_instance_of(EE::Project).to receive(:add_import_job)

        new_user = create(:user)
        project.add_master(new_user)

        post :create, namespace_id: project.namespace.to_param,
                      project_id: project,
                      project: { mirror: true, mirror_user_id: new_user.id, import_url: 'http://local.dev' },
                      format: :json

        expect(project.reload.mirror).to eq(true)
        expect(project.reload.mirror_user.id).to eq(user.id)
      end
    end
  end
end

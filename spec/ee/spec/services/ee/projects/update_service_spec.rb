require 'spec_helper'

describe Projects::UpdateService, '#execute' do
  let(:user) { create(:user) }
  let(:project) { create(:project, creator: user, namespace: user.namespace) }

  context 'repository mirror' do
    let!(:opts) do
      {
        import_url: 'http://foo.com',
        mirror: true,
        mirror_user_id: user.id,
        mirror_trigger_builds: true
      }
    end

    context 'when licensed' do
      before do
        stub_licensed_features(repository_mirrors: true)
      end

      it 'updates the correct attributes' do
        update_project(project, user, opts)

        updated_project = project.reload
        expect(updated_project).to be_valid
        expect(updated_project.mirror).to be true
        expect(updated_project.mirror_user_id).to eq(user.id)
        expect(updated_project.mirror_trigger_builds).to be true
      end
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(repository_mirrors: false)
      end

      it 'does not update mirror attributes' do
        update_project(project, user, opts)

        updated_project = project.reload
        expect(updated_project).to be_valid
        expect(updated_project.mirror).to be false
        expect(updated_project.mirror_user_id).to be_nil
        expect(updated_project.mirror_trigger_builds).to be false
      end
    end
  end

  def update_project(project, user, opts)
    Projects::UpdateService.new(project, user, opts).execute
  end
end

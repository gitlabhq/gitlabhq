require 'spec_helper'

describe Users::DestroyService do
  context 'when project is a mirror' do
    it 'assigns mirror_user to a project owner' do
      mirror_user = create(:user)
      project = create(:project, :mirror, mirror_user_id: mirror_user.id)
      new_mirror_user = project.team.owners.first

      expect_any_instance_of(EE::NotificationService).to receive(:project_mirror_user_changed).with(new_mirror_user, mirror_user.name, project)

      expect do
        described_class.new(mirror_user).execute(mirror_user)
      end.to change { project.reload.mirror_user }.from(mirror_user).to(new_mirror_user)
    end
  end
end

require 'spec_helper'

describe GroupsHelper do
  describe 'group_icon' do
    avatar_file_path = File.join(Rails.root, 'spec', 'fixtures', 'banana_sample.gif')

    it 'returns an url for the avatar' do
      group = create(:group)
      group.avatar = File.open(avatar_file_path)
      group.save!
      expect(group_icon(group.path).to_s).
        to match("/uploads/group/avatar/#{group.id}/banana_sample.gif")
    end

    it 'gives default avatar_icon when no avatar is present' do
      group = create(:group)
      group.save!
      expect(group_icon(group.path)).to match('group_avatar.png')
    end
  end

  describe 'group_lfs_status' do
    let(:group) { create(:group) }
    let!(:project) { create(:empty_project, namespace_id: group.id) }

    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
    end

    context 'only one project in group' do
      before do
        group.update_attribute(:lfs_enabled, true)
      end

      it 'returns all projects as enabled' do
        expect(group_lfs_status(group)).to include('Enabled for all projects')
      end

      it 'returns all projects as disabled' do
        project.update_attribute(:lfs_enabled, false)

        expect(group_lfs_status(group)).to include('Enabled for 0 out of 1 project')
      end
    end

    context 'more than one project in group' do
      before do
        create(:empty_project, namespace_id: group.id)
      end

      context 'LFS enabled in group' do
        before do
          group.update_attribute(:lfs_enabled, true)
        end

        it 'returns both projects as enabled' do
          expect(group_lfs_status(group)).to include('Enabled for all projects')
        end

        it 'returns only one as enabled' do
          project.update_attribute(:lfs_enabled, false)

          expect(group_lfs_status(group)).to include('Enabled for 1 out of 2 projects')
        end
      end

      context 'LFS disabled in group' do
        before do
          group.update_attribute(:lfs_enabled, false)
        end

        it 'returns both projects as disabled' do
          expect(group_lfs_status(group)).to include('Disabled for all projects')
        end

        it 'returns only one as disabled' do
          project.update_attribute(:lfs_enabled, true)

          expect(group_lfs_status(group)).to include('Disabled for 1 out of 2 projects')
        end
      end
    end
  end
end

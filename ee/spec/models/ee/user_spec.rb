require 'spec_helper'

describe EE::User do
  describe 'associations' do
    subject { build(:user) }

    it { is_expected.to have_many(:vulnerability_feedback) }
  end

  describe "scopes" do
    describe '.excluding_guests' do
      let!(:user_without_membership) { create(:user).id }
      let!(:project_guest_user)      { create(:project_member, :guest).user_id }
      let!(:project_reporter_user)   { create(:project_member, :reporter).user_id }
      let!(:group_guest_user)        { create(:group_member, :guest).user_id }
      let!(:group_reporter_user)     { create(:group_member, :reporter).user_id }

      it 'exclude users with a Guest role in a Project/Group' do
        user_ids = User.excluding_guests.pluck(:id)

        expect(user_ids).to include(project_reporter_user)
        expect(user_ids).to include(group_reporter_user)

        expect(user_ids).not_to include(user_without_membership)
        expect(user_ids).not_to include(project_guest_user)
        expect(user_ids).not_to include(group_guest_user)
      end
    end
  end

  describe '#access_level=' do
    let(:user) { build(:user) }

    before do
      # `auditor?` returns true only when the user is an auditor _and_ the auditor license
      # add-on is present. We aren't testing this here, so we can assume that the add-on exists.
      stub_licensed_features(auditor_user: true)
    end

    it "does not set 'auditor' for an invalid access level" do
      user.access_level = :invalid_access_level

      expect(user.auditor).to be false
    end

    it "does not set 'auditor' for admin level" do
      user.access_level = :admin

      expect(user.auditor).to be false
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :regular

      expect(user.access_level).to eq(:regular)
      expect(user.admin).to be false
      expect(user.auditor).to be false
    end

    it "clears the 'admin' access level when a user is made an auditor" do
      user.access_level = :admin
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "clears the 'auditor' access level when a user is made an admin" do
      user.access_level = :auditor
      user.access_level = :admin

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
      expect(user.auditor).to be false
    end

    it "doesn't clear existing 'auditor' access levels when an invalid access level is passed in" do
      user.access_level = :auditor
      user.access_level = :invalid_access_level

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end
  end

  describe '#full_private_access?' do
    it 'returns true for auditor user' do
      user = build(:user, :auditor)

      expect(user.full_private_access?).to be_truthy
    end
  end

  describe '#forget_me!' do
    subject { create(:user, remember_created_at: Time.now) }

    it 'clears remember_created_at' do
      subject.forget_me!

      expect(subject.reload.remember_created_at).to be_nil
    end

    it 'does not clear remember_created_at when in a GitLab read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { subject.forget_me! }.not_to change(subject, :remember_created_at)
    end
  end

  describe '#remember_me!' do
    subject { create(:user, remember_created_at: nil) }

    it 'updates remember_created_at' do
      subject.remember_me!

      expect(subject.reload.remember_created_at).not_to be_nil
    end

    it 'does not update remember_created_at when in a Geo read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { subject.remember_me! }.not_to change(subject, :remember_created_at)
    end
  end

  describe '#email_opted_in_source' do
    context 'for GitLab.com' do
      let(:user) { build(:user, email_opted_in_source_id: 1) }

      it 'returns GitLab.com' do
        expect(user.email_opted_in_source).to eq('GitLab.com')
      end
    end

    context 'for nil source id' do
      let(:user) { build(:user, email_opted_in_source_id: nil) }

      it 'returns blank' do
        expect(user.email_opted_in_source).to be_blank
      end
    end

    context 'for non-existent source id' do
      let(:user) { build(:user, email_opted_in_source_id: 2) }

      it 'returns blank' do
        expect(user.email_opted_in_source).to be_blank
      end
    end
  end

  describe '#available_custom_project_templates' do
    let(:user) { create(:user) }

    it 'returns an empty relation if group is not set' do
      expect(user.available_custom_project_templates.empty?).to be_truthy
    end

    context 'when group with custom project templates is set' do
      let(:group) { create(:group) }

      before do
        stub_ee_application_setting(custom_project_templates_group_id: group.id)
      end

      it 'returns an empty relation if group has no available project templates' do
        expect(group.projects.empty?).to be true
        expect(user.available_custom_project_templates.empty?).to be true
      end

      context 'when group has custom project templates' do
        let!(:private_project) { create :project, :private, namespace: group, name: 'private_project' }
        let!(:internal_project) { create :project, :internal, namespace: group, name: 'internal_project' }
        let!(:public_project) { create :project, :public, namespace: group, name: 'public_project' }

        it 'returns public projects' do
          expect(user.available_custom_project_templates).to include public_project
        end

        context 'returns private projects if user' do
          it 'is a member of the project' do
            expect(user.available_custom_project_templates).not_to include private_project

            private_project.add_developer(user)

            expect(user.available_custom_project_templates).to include private_project
          end

          it 'is a member of the group' do
            expect(user.available_custom_project_templates).not_to include private_project

            group.add_developer(user)

            expect(user.available_custom_project_templates).to include private_project
          end
        end

        it 'returns internal projects' do
          expect(user.available_custom_project_templates).to include internal_project
        end

        it 'allows to search available project templates by name' do
          projects = user.available_custom_project_templates(search: 'publi')

          expect(projects.count).to eq 1
          expect(projects.first).to eq public_project
        end
      end
    end
  end
end

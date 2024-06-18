# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserGroupNotificationSettingsFinder, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  subject { described_class.new(user, Group.where(id: groups.map(&:id))).execute }

  def attributes(&proc)
    subject.map(&proc).uniq
  end

  context 'when the groups have no existing notification settings' do
    context 'when the groups have no ancestors' do
      let_it_be(:groups) { create_list(:group, 3) }

      it 'will be a default Global notification setting', :aggregate_failures do
        expect(subject.count).to eq(3)
        expect(attributes(&:notification_email)).to match_array([nil])
        expect(attributes(&:level)).to match_array(['global'])
      end
    end

    context 'when the groups have ancestors' do
      context 'when an ancestor has a level other than Global' do
        let_it_be(:ancestor_a) { create(:group) }
        let_it_be(:group_a) { create(:group, parent: ancestor_a) }
        let_it_be(:ancestor_b) { create(:group) }
        let_it_be(:group_b) { create(:group, parent: ancestor_b) }
        let_it_be(:email) { create(:email, :confirmed, email: 'ancestor@example.com', user: user) }

        let_it_be(:groups) { [group_a, group_b] }

        before do
          create(:notification_setting, user: user, source: ancestor_a, level: 'participating', notification_email: email.email)
          create(:notification_setting, user: user, source: ancestor_b, level: 'participating', notification_email: email.email)
        end

        it 'has the same level set' do
          expect(attributes(&:level)).to match_array(['participating'])
        end

        it 'has the same email set' do
          expect(attributes(&:notification_email)).to match_array(['ancestor@example.com'])
        end

        it 'only returns the two queried groups' do
          expect(subject.count).to eq(2)
        end
      end

      context 'when an ancestor has a Global level but has an email set' do
        let_it_be(:grand_ancestor) { create(:group) }
        let_it_be(:ancestor) { create(:group, parent: grand_ancestor) }
        let_it_be(:group) { create(:group, parent: ancestor) }
        let_it_be(:ancestor_email) { create(:email, :confirmed, email: 'ancestor@example.com', user: user) }
        let_it_be(:grand_email) { create(:email, :confirmed, email: 'grand@example.com', user: user) }

        let_it_be(:groups) { [group] }

        before do
          create(:notification_setting, user: user, source: grand_ancestor, level: 'participating', notification_email: grand_email.email)
          create(:notification_setting, user: user, source: ancestor, level: 'global', notification_email: ancestor_email.email)
        end

        it 'has the same email and level set', :aggregate_failures do
          expect(subject.count).to eq(1)
          expect(attributes(&:level)).to match_array(['global'])
          expect(attributes(&:notification_email)).to match_array(['ancestor@example.com'])
        end
      end

      context 'when the group has a private parent' do
        let_it_be(:ancestor) { create(:group, :private) }
        let_it_be(:group) { create(:group, :private, parent: ancestor) }
        let_it_be(:ancestor_email) { create(:email, :confirmed, email: 'ancestor@example.com', user: user) }
        let_it_be(:groups) { [group] }

        before do
          group.add_reporter(user)
          # Adding the user creates a NotificationSetting, so we remove it here
          user.notification_settings.where(source: group).delete_all

          create(:notification_setting, user: user, source: ancestor, level: 'participating', notification_email: ancestor_email.email)
        end

        it 'still inherits the notification settings' do
          expect(subject.count).to eq(1)
          expect(attributes(&:level)).to match_array(['participating'])
          expect(attributes(&:notification_email)).to match_array([ancestor_email.email])
        end
      end

      it 'does not cause an N+1', :aggregate_failures do
        parent = create(:group)
        child = create(:group, parent: parent)

        control = ActiveRecord::QueryRecorder.new do
          described_class.new(user, Group.where(id: child.id)).execute
        end

        other_parent = create(:group)
        other_children = create_list(:group, 2, parent: other_parent)

        result = nil

        expect do
          result = described_class.new(user, Group.where(id: other_children.append(child).map(&:id))).execute
        end.not_to exceed_query_limit(control)

        expect(result.count).to eq(3)
      end

      context 'preloading `emails_enabled`' do
        let_it_be(:root_group) { create(:group) }
        let_it_be(:sub_group) { create(:group, parent: root_group) }
        let_it_be(:sub_sub_group) { create(:group, parent: sub_group) }

        let_it_be(:another_root_group) { create(:group) }
        let_it_be(:sub_group_with_emails_disabled) { create(:group, emails_enabled: false, parent: another_root_group) }
        let_it_be(:another_sub_sub_group) { create(:group, parent: sub_group_with_emails_disabled) }

        let_it_be(:root_group_with_emails_disabled) { create(:group, emails_enabled: false) }
        let_it_be(:group) { create(:group, parent: root_group_with_emails_disabled) }

        let(:groups) { Group.where(id: [sub_sub_group, another_sub_sub_group, group]) }

        before do
          described_class.new(user, groups).execute
        end

        it 'preloads the `group.emails_enabled` method' do
          recorder = ActiveRecord::QueryRecorder.new do
            groups.each(&:emails_enabled?)
          end

          expect(recorder.count).to eq(0)
        end

        it 'preloads the `group.emails_enabled` method correctly' do
          groups.each do |group|
            expect(group.emails_enabled?).to eq(Group.find(group.id).emails_enabled?) # compare the memoized and the freshly loaded value
          end
        end
      end
    end
  end
end

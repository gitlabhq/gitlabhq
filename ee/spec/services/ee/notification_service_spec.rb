require 'spec_helper'

describe EE::NotificationService, :mailer do
  include NotificationHelpers
  include ExternalAuthorizationServiceHelpers
  let(:subject) { NotificationService.new }

  context 'with external authentication service' do
    let(:issue) { create(:issue) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }
    let(:member) { create(:user) }

    before do
      project.add_maintainer(member)
      member.global_notification_setting.update!(level: :watch)
    end

    it 'sends email when the service is not enabled' do
      expect(Notify).to receive(:new_issue_email).with(member.id, issue.id, nil).and_call_original

      subject.new_issue(issue, member)
    end

    context 'when the service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it 'does not send an email' do
        expect(Notify).not_to receive(:new_issue_email)

        subject.new_issue(issue, member)
      end

      it 'still delivers email to admins' do
        member.update!(admin: true)

        expect(Notify).to receive(:new_issue_email).with(member.id, issue.id, nil).and_call_original

        subject.new_issue(issue, member)
      end
    end
  end

  context 'service desk issues' do
    before do
      allow(Notify).to receive(:service_desk_new_note_email)
                         .with(kind_of(Integer), kind_of(Integer)).and_return(double(deliver_later: true))

      allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(true)
      allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
      allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
    end

    def should_email!
      expect(Notify).to receive(:service_desk_new_note_email).with(issue.id, kind_of(Integer))
    end

    def should_not_email!
      expect(Notify).not_to receive(:service_desk_new_note_email)
    end

    def execute!
      subject.new_note(note)
    end

    def self.it_should_email!
      it 'sends the email' do
        should_email!
        execute!
      end
    end

    def self.it_should_not_email!
      it 'doesn\'t send the email' do
        should_not_email!
        execute!
      end
    end

    let(:issue) { create(:issue, author: User.support_bot) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }

    context 'a non-service-desk issue' do
      it_should_not_email!
    end

    context 'a service-desk issue' do
      before do
        issue.update!(service_desk_reply_to: 'service.desk@example.com')
        project.update!(service_desk_enabled: true)
      end

      it_should_email!

      context 'where the project has disabled the feature' do
        before do
          project.update(service_desk_enabled: false)
        end

        it_should_not_email!
      end

      context 'when the license doesn\'t allow service desk' do
        before do
          allow(::EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
        end

        it_should_not_email!
      end

      context 'when the support bot has unsubscribed' do
        before do
          issue.unsubscribe(User.support_bot, project)
        end

        it_should_not_email!
      end
    end
  end

  describe 'mirror hard failed' do
    let(:user) { create(:user) }

    context 'when the project has invited members' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)
        create(:project_member, :invited, project: project)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end
    end

    context 'when user is owner' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      context 'when owner is blocked' do
        it 'does not send email' do
          project = create(:project, :mirror, :import_hard_failed)
          project.owner.block!

          expect(Notify).not_to receive(:mirror_was_hard_failed_email)

          subject.mirror_was_hard_failed(project)
        end

        context 'when project belongs to group' do
          it 'does not send email to the blocked owner' do
            blocked_user = create(:user, :blocked)

            group = create(:group, :public)
            group.add_owner(blocked_user)
            group.add_owner(user)

            project = create(:project, :mirror, :import_hard_failed, namespace: group)

            expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, blocked_user.id).and_call_original
            expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

            subject.mirror_was_hard_failed(project)
          end
        end
      end
    end

    context 'when user is maintainer' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_maintainer(user)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end
    end

    context 'when user is not owner nor maintainer' do
      it 'does not send email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_developer(user)

        expect(Notify).not_to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.creator.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end

      context 'when user is group owner' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_owner(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end

      context 'when user is group maintainer' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_maintainer(user)
          end

          project = create(:project, :mirror, :import_hard_failed, namespace: group)

          expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

          subject.mirror_was_hard_failed(project)
        end
      end
    end
  end

  context 'mirror user changed' do
    it 'sends email' do
      mirror_user = create(:user)
      project = create(:project, :mirror, mirror_user_id: mirror_user.id)
      new_mirror_user = project.team.owners.first

      expect(Notify).to receive(:project_mirror_user_changed_email).with(new_mirror_user.id, mirror_user.name, project.id).and_call_original

      subject.project_mirror_user_changed(new_mirror_user, mirror_user.name, project)
    end
  end

  describe '#prometheus_alerts_fired' do
    it 'sends the email to owners and masters' do
      project = create(:project)
      prometheus_alert = create(:prometheus_alert, project: project)
      master = create(:user)
      developer = create(:user)

      project.add_master(master)

      expect(Notify).to receive(:prometheus_alert_fired_email).with(project.id, master.id, prometheus_alert).and_call_original
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project.id, project.owner.id, prometheus_alert).and_call_original
      expect(Notify).not_to receive(:prometheus_alert_fired_email).with(project.id, developer.id, prometheus_alert)

      subject.prometheus_alerts_fired(prometheus_alert.project, [prometheus_alert])
    end
  end

  describe 'Notes' do
    around do |example|
      perform_enqueued_jobs do
        example.run
      end
    end

    context 'epic notes' do
      set(:group) { create(:group, :private) }
      set(:epic) { create(:epic, group: group) }
      set(:note) { create(:note, project: nil, noteable: epic, note: '@mention referenced, @unsubscribed_mentioned and @outsider also') }

      before(:all) do
        create(:group_member, group: group, user: epic.author)
        create(:group_member, group: group, user: note.author)
      end

      before do
        stub_licensed_features(epics: true)
        build_group_members(group)

        @u_custom_off = create_user_with_notification(:custom, 'custom_off', group)
        create(:group_member, group: group, user: @u_custom_off)

        create(
          :note,
          project: nil,
          noteable: epic,
          author: @u_custom_off,
          note: 'i think @subscribed_participant should see this'
        )

        update_custom_notification(:new_note, @u_guest_custom, resource: group)
        update_custom_notification(:new_note, @u_custom_global)
      end

      describe '#new_note' do
        it do
          add_users_with_subscription(group, epic)
          reset_delivered_emails!

          expect(SentNotification).to receive(:record).with(epic, any_args).exactly(9).times

          subject.new_note(note)

          should_email(@u_watcher)
          should_email(note.noteable.author)
          should_email(@u_custom_global)
          should_email(@u_mentioned)
          should_email(@subscriber)
          should_email(@watcher_and_subscriber)
          should_email(@subscribed_participant)
          should_email(@u_custom_off)
          should_email(@unsubscribed_mentioned)
          should_not_email(@u_guest_custom)
          should_not_email(@u_guest_watcher)
          should_not_email(note.author)
          should_not_email(@u_participating)
          should_not_email(@u_disabled)
          should_not_email(@unsubscriber)
          should_not_email(@u_outsider_mentioned)
          should_not_email(@u_lazy_participant)
        end
      end
    end
  end

  def build_group_members(group)
    @u_watcher               = create_global_setting_for(create(:user), :watch)
    @u_participating         = create_global_setting_for(create(:user), :participating)
    @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
    @u_disabled              = create_global_setting_for(create(:user), :disabled)
    @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
    @u_committer             = create(:user, username: 'committer')
    @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
    @u_outsider_mentioned    = create(:user, username: 'outsider')
    @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

    # User to be participant by default
    # This user does not contain any record in notification settings table
    # It should be treated with a :participating notification_level
    @u_lazy_participant      = create(:user, username: 'lazy-participant')

    @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching', group)
    @u_guest_custom = create_user_with_notification(:custom, 'guest_custom', group)

    create(:group_member, group: group, user: @u_watcher)
    create(:group_member, group: group, user: @u_participating)
    create(:group_member, group: group, user: @u_participant_mentioned)
    create(:group_member, group: group, user: @u_disabled)
    create(:group_member, group: group, user: @u_mentioned)
    create(:group_member, group: group, user: @u_committer)
    create(:group_member, group: group, user: @u_not_mentioned)
    create(:group_member, group: group, user: @u_lazy_participant)
    create(:group_member, group: group, user: @u_custom_global)
  end

  def add_users_with_subscription(group, issuable)
    @subscriber = create :user
    @unsubscriber = create :user
    @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
    @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
    @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

    create(:group_member, group: group, user: @subscribed_participant)
    create(:group_member, group: group, user: @subscriber)
    create(:group_member, group: group, user: @unsubscriber)
    create(:group_member, group: group, user: @watcher_and_subscriber)
    create(:group_member, group: group, user: @unsubscribed_mentioned)

    issuable.subscriptions.create(user: @unsubscribed_mentioned, subscribed: false)
    issuable.subscriptions.create(user: @subscriber, subscribed: true)
    issuable.subscriptions.create(user: @subscribed_participant, subscribed: true)
    issuable.subscriptions.create(user: @unsubscriber, subscribed: false)
    # Make the watcher a subscriber to detect dupes
    issuable.subscriptions.create(user: @watcher_and_subscriber, subscribed: true)
  end
end

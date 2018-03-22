require 'spec_helper'

describe EE::NotificationService, :mailer do
  include ExternalAuthorizationServiceHelpers
  let(:subject) { NotificationService.new }

  context 'with external authentication service' do
    let(:issue) { create(:issue) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }
    let(:member) { create(:user) }

    before do
      project.add_master(member)
      member.global_notification_setting.update!(level: :watch)
    end

    it 'sends email when the service is not enabled' do
      expect(Notify).to receive(:new_issue_email).with(member.id, issue.id, nil).and_call_original

      subject.new_issue(issue, member)
    end

    context 'when the service is enabled' do
      before do
        enable_external_authorization_service
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
      subject.send_service_desk_notification(note)
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
          expect(EE::Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
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

    context 'when user is master' do
      it 'sends email' do
        project = create(:project, :mirror, :import_hard_failed)
        project.add_master(user)

        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, project.owner.id).and_call_original
        expect(Notify).to receive(:mirror_was_hard_failed_email).with(project.id, user.id).and_call_original

        subject.mirror_was_hard_failed(project)
      end
    end

    context 'when user is not owner nor master' do
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

      context 'when user is group master' do
        it 'sends email' do
          group = create(:group, :public) do |group|
            group.add_master(user)
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
end

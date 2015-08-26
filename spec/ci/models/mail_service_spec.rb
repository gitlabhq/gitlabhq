# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe MailService do
  describe "Associations" do
    it { should belong_to :project }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end
    end
  end

  describe 'Sends email for' do
    let(:mail)   { MailService.new }

    describe 'failed build' do
      let(:project) { FactoryGirl.create(:project, email_add_pusher: true) }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :failed, commit: commit) }

      before do
        mail.stub(
          project: project
        )
      end

      it do
        should_email("git@example.com")
        mail.execute(build)
      end

      def should_email(email)
        Notify.should_receive(:build_fail_email).with(build.id, email)
        Notify.should_not_receive(:build_success_email).with(build.id, email)
      end
    end

    describe 'successfull build' do
      let(:project) { FactoryGirl.create(:project, email_add_pusher: true, email_only_broken_builds: false) }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :success, commit: commit) }

      before do
        mail.stub(
          project: project
        )
      end

      it do
        should_email("git@example.com")
        mail.execute(build)
      end

      def should_email(email)
        Notify.should_receive(:build_success_email).with(build.id, email)
        Notify.should_not_receive(:build_fail_email).with(build.id, email)
      end
    end

    describe 'successfull build and project has email_recipients' do
      let(:project) {
        FactoryGirl.create(:project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :success, commit: commit) }

      before do
        mail.stub(
          project: project
        )
      end

      it do
        should_email("git@example.com")
        should_email("jeroen@example.com")
        mail.execute(build)
      end

      def should_email(email)
        Notify.should_receive(:build_success_email).with(build.id, email)
        Notify.should_not_receive(:build_fail_email).with(build.id, email)
      end
    end

    describe 'successful build and notify only broken builds' do
      let(:project) {
        FactoryGirl.create(:project,
                           email_add_pusher: true,
                           email_only_broken_builds: true,
                           email_recipients: "jeroen@example.com")
      }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :success, commit: commit) }

      before do
        mail.stub(
          project: project
        )
      end

      it do
        should_email(commit.git_author_email)
        should_email("jeroen@example.com")
        mail.execute(build) if mail.can_execute?(build)
      end

      def should_email(email)
        Notify.should_not_receive(:build_success_email).with(build.id, email)
        Notify.should_not_receive(:build_fail_email).with(build.id, email)
      end
    end

    describe 'successful build and can test service' do
      let(:project) {
        FactoryGirl.create(:project,
                           email_add_pusher: true,
                           email_only_broken_builds: false,
                           email_recipients: "jeroen@example.com")
      }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :success, commit: commit) }

      before do
        mail.stub(
          project: project
        )
        build
      end

      it do
        mail.can_test?.should == true
      end
    end

    describe 'retried build should not receive email' do
      let(:project) {
        FactoryGirl.create(:project,
                           email_add_pusher: true,
                           email_only_broken_builds: true,
                           email_recipients: "jeroen@example.com")
      }
      let(:commit) { FactoryGirl.create(:commit, project: project) }
      let(:build) { FactoryGirl.create(:build, status: :failed, commit: commit) }

      before do
        mail.stub(
          project: project
        )
      end

      it do
        Build.retry(build)
        should_email(commit.git_author_email)
        should_email("jeroen@example.com")
        mail.execute(build) if mail.can_execute?(build)
      end

      def should_email(email)
        Notify.should_not_receive(:build_success_email).with(build.id, email)
        Notify.should_not_receive(:build_fail_email).with(build.id, email)
      end
    end
  end
end

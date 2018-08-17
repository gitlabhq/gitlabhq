require 'spec_helper'

describe JenkinsService do
  let(:project) { create(:project) }
  let(:jenkins_url) { 'http://jenkins.example.com/' }
  let(:jenkins_hook_url) { jenkins_url + 'project/my_project' }
  let(:jenkins_username) { 'u$er name%2520' }
  let(:jenkins_password) { 'pas$ word' }

  let(:jenkins_params) do
    {
      active: true,
      project: project,
      properties: {
        password: jenkins_password,
        username: jenkins_username,
        jenkins_url: jenkins_url,
        project_name: 'my_project'
      }
    }
  end

  let(:jenkins_authorization) { "Basic " + ::Base64.strict_encode64(jenkins_username + ':' + jenkins_password) }

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'username validation' do
    before do
      @jenkins_service = described_class.create(
        active: active,
        project: project,
        properties: {
          jenkins_url: 'http://jenkins.example.com/',
          password: 'password',
          username: 'username'
        }
      )
    end

    subject { @jenkins_service }

    context 'when the service is active' do
      let(:active) { true }

      context 'when password was not touched' do
        before do
          allow(subject).to receive(:password_touched?).and_return(false)
        end

        it { is_expected.not_to validate_presence_of :username }
      end

      context 'when password was touched' do
        before do
          allow(subject).to receive(:password_touched?).and_return(true)
        end

        it { is_expected.to validate_presence_of :username }
      end
    end

    context 'when the service is inactive' do
      let(:active) { false }

      it { is_expected.not_to validate_presence_of :username }
    end
  end

  describe '#hook_url' do
    let(:username) { nil }
    let(:password) { nil }
    let(:jenkins_service) do
      described_class.new(
        project: project,
        properties: {
          jenkins_url: jenkins_url,
          project_name: 'my_project',
          username: username,
          password: password
        }
      )
    end

    subject { jenkins_service.hook_url }

    context 'when the jenkins_url has no relative path' do
      let(:jenkins_url) { 'http://jenkins.example.com/' }

      it { is_expected.to eq('http://jenkins.example.com/project/my_project') }
    end

    context 'when the jenkins_url has relative path' do
      let(:jenkins_url) { 'http://organization.example.com/jenkins' }

      it { is_expected.to eq('http://organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is missing and username and password are set' do
      let(:jenkins_url) { 'http://organization.example.com/jenkins' }
      let(:username) { 'u$ername' }
      let(:password) { 'pas$ word' }

      it { is_expected.to eq('http://u%24ername:pas%24%20word@organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is provided and username and password are set' do
      let(:jenkins_url) { 'http://u:p@organization.example.com/jenkins' }
      let(:username) { 'username' }
      let(:password) { 'password' }

      it { is_expected.to eq('http://username:password@organization.example.com/jenkins/project/my_project') }
    end

    context 'userinfo is provided username and password are not set' do
      let(:jenkins_url) { 'http://u:p@organization.example.com/jenkins' }

      it { is_expected.to eq('http://u:p@organization.example.com/jenkins/project/my_project') }
    end
  end

  describe '#test' do
    it 'returns the right status' do
      user = create(:user, username: 'username')
      project = create(:project, name: 'project')
      push_sample_data = Gitlab::DataBuilder::Push.build_sample(project, user)
      jenkins_service = described_class.create(jenkins_params)
      stub_request(:post, jenkins_hook_url).with(headers: { 'Authorization' => jenkins_authorization })

      result = jenkins_service.test(push_sample_data)

      expect(result).to eq({ success: true, result: '' })
    end
  end

  shared_examples 'project with disabled Jenkins service' do
    it 'does not invoke the Jenkins API' do
      jenkins_service.execute(push_sample_data)

      expect(a_request(:any, jenkins_hook_url)).not_to have_been_made
    end
  end

  shared_examples 'project with enabled Jenkins service' do
    it 'invokes the Jenkins API' do
      jenkins_service.execute(push_sample_data)

      expect(a_request(:post, jenkins_hook_url)).to have_been_made.once
    end
  end

  describe '#execute' do
    let(:user) { create(:user, username: 'username') }
    let(:namespace) { create(:group, :private) }
    let(:project) { create(:project, :private, name: 'project', namespace: namespace) }
    let(:push_sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:jenkins_service) { described_class.create(jenkins_params) }

    before do
      stub_request(:post, jenkins_hook_url)
    end

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable DestroyAll
      end

      it_behaves_like 'project with disabled Jenkins service'
    end

    context 'with a license key' do
      context 'when namespace plan check is not enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: false)
        end

        it_behaves_like 'project with enabled Jenkins service'
      end

      context 'when namespace plan check is enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: true)
        end

        context 'when namespace does not have a plan' do
          let(:namespace) { create(:group, :private) }

          it_behaves_like 'project with disabled Jenkins service'
        end

        context 'when namespace has a plan' do
          let(:namespace) { create(:group, :private, plan: :bronze_plan) }

          it 'adds default web hook headers to the request' do
            jenkins_service.execute(push_sample_data)

            expect(
              a_request(:post, jenkins_hook_url)
                .with(headers: { 'X-Gitlab-Event' => 'Push Hook', 'Authorization' => jenkins_authorization })
            ).to have_been_made.once
          end

          it 'request url contains properly serialized username and password' do
            jenkins_service.execute(push_sample_data)

            expect(
              a_request(:post, 'http://jenkins.example.com/project/my_project')
                .with(headers: { 'Authorization' => jenkins_authorization })
            ).to have_been_made.once
          end
        end
      end
    end
  end

  describe 'Stored password invalidation' do
    let(:project) { create(:project) }

    context 'when a password was previously set' do
      before do
        @jenkins_service = described_class.create(
          project: project,
          properties: {
            jenkins_url: 'http://jenkins.example.com/',
            username: 'jenkins',
            password: 'password'
          }
        )
      end

      it 'resets password if url changed' do
        @jenkins_service.jenkins_url = 'http://jenkins-edited.example.com/'
        @jenkins_service.save
        expect(@jenkins_service.password).to be_nil
      end

      it 'resets password if username is blank' do
        @jenkins_service.username = ''
        @jenkins_service.save
        expect(@jenkins_service.password).to be_nil
      end

      it 'does not reset password if username changed' do
        @jenkins_service.username = 'some_name'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
      end

      it 'does not reset password if new url is set together with password, even if it\'s the same password' do
        @jenkins_service.jenkins_url = 'http://jenkins_edited.example.com/'
        @jenkins_service.password = 'password'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
        expect(@jenkins_service.jenkins_url).to eq('http://jenkins_edited.example.com/')
      end

      it 'resets password if url changed, even if setter called multiple times' do
        @jenkins_service.jenkins_url = 'http://jenkins1.example.com/'
        @jenkins_service.jenkins_url = 'http://jenkins1.example.com/'
        @jenkins_service.save
        expect(@jenkins_service.password).to be_nil
      end
    end

    context 'when no password was previously set' do
      before do
        @jenkins_service = described_class.create(
          project: create(:project),
          properties: {
            jenkins_url: 'http://jenkins.example.com/',
            username: 'jenkins'
          }
        )
      end

      it 'saves password if new url is set together with password' do
        @jenkins_service.jenkins_url = 'http://jenkins_edited.example.com/'
        @jenkins_service.password = 'password'
        @jenkins_service.save
        expect(@jenkins_service.password).to eq('password')
        expect(@jenkins_service.jenkins_url).to eq('http://jenkins_edited.example.com/')
      end
    end
  end
end

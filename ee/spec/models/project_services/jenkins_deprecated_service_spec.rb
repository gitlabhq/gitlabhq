require 'spec_helper'

describe JenkinsDeprecatedService, use_clean_rails_memory_store_caching: true do
  include ReactiveCachingHelpers

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'commits methods' do
    def status_body_for_icon(state)
      <<ICON_STATUS_HTML
      <h1 class="build-caption page-headline">
        <img src="/static/8b0a9b52/images/48x48/#{state}" alt="Success" tooltip="Success" style="width: 48px; height: 48px; " class="icon-#{state} icon-xlg" />
        Build #188
        (Oct 15, 2014 9:45:21 PM)
      </h1>
ICON_STATUS_HTML
    end

    describe '#calculate_reactive_cache' do
      let(:pass_unstable) { '0' }
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '0',
          pass_unstable: pass_unstable,
          token: 'verySecret'
        )
      end

      statuses = { 'blue.png' => 'success', 'yellow.png' => 'failed', 'red.png' => 'failed', 'aborted.png' => 'failed', 'blue-anime.gif' => 'running', 'grey.png' => 'pending' }
      statuses.each do |icon, state|
        it "has a commit_status of #{state} when the icon #{icon} exists." do
          stub_request(:get, "http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: status_body_for_icon(icon), headers: {})

          expect(@service.calculate_reactive_cache('2ab7834c', 'master')).to eq(commit_status: state)
        end
      end

      context 'with passing unstable' do
        let(:pass_unstable) { '1' }

        it 'has a commit_status of success when the icon yellow exists' do
          stub_request(:get, "http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: status_body_for_icon('yellow.png'), headers: {})

          expect(@service.calculate_reactive_cache('2ab7834c', 'master')).to eq(commit_status: 'success')
        end
      end

      context 'with bad response' do
        it 'has a commit_status of error' do
          stub_request(:get, "http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: '<h1>404</h1>', headers: {})
          expect(@service.calculate_reactive_cache('2ab7834c', 'master')).to eq(commit_status: :error)
        end
      end
    end

    describe '#commit_status' do
      subject(:service) { described_class.new(project_id: 666) }

      it 'returns the contents of the reactive cache' do
        stub_reactive_cache(service, { commit_status: 'foo' }, 'sha', 'ref')

        expect(service.commit_status('sha', 'ref')).to eq('foo')
      end
    end

    describe 'multiproject enabled' do
      let!(:project) { create(:project) }
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '1',
          token: 'verySecret',
          project: project
        )
      end

      describe '#build_page' do
        it { expect(@service.build_page("2ab7834c", 'feature/my-branch')).to eq("http://jenkins.gitlab.org/job/#{project.name}_feature_my-branch/scm/bySHA1/2ab7834c") }
      end
    end

    describe 'multiproject disabled' do
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '0',
          token: 'verySecret'
        )
      end

      describe '#build_page' do
        it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c") }
      end

      describe '#build_page with branch' do
        it { expect(@service.build_page("2ab7834c", 'test_branch')).to eq("http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c") }
      end
    end
  end

  shared_examples 'a disabled jenkins deprecated service' do
    it 'does not invoke the service hook' do
      expect_any_instance_of(ServiceHook).not_to receive(:execute)

      jenkins_service.execute(push_sample_data)
    end
  end

  shared_examples 'an enabled jenkins deprecated service' do
    it 'invokes the service hook' do
      expect_any_instance_of(ServiceHook).to receive(:execute)

      jenkins_service.execute(push_sample_data)
    end
  end

  describe '#execute' do
    let(:user) { create(:user, username: 'username') }
    let(:namespace) { create(:group, :private) }
    let(:project) { create(:project, :private, name: 'project', namespace: namespace) }
    let(:push_sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:jenkins_service) { described_class.create(active: true, project: project) }
    let!(:service_hook) { create(:service_hook, service: jenkins_service) }

    context 'without a license key' do
      before do
        License.destroy_all # rubocop: disable DestroyAll
      end

      it_behaves_like 'a disabled jenkins deprecated service'
    end

    context 'with a license key' do
      context 'when namespace plan check is not enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: false)
        end

        it_behaves_like 'an enabled jenkins deprecated service'
      end

      context 'when namespace plan check is enabled' do
        before do
          stub_application_setting_on_object(project, should_check_namespace_plan: true)
        end

        context 'when namespace does not have a plan' do
          let(:namespace) { create(:group, :private) }

          it_behaves_like 'a disabled jenkins deprecated service'
        end

        context 'when namespace has a plan' do
          let(:namespace) { create(:group, :private, plan: :bronze_plan) }

          it_behaves_like 'an enabled jenkins deprecated service'
        end
      end
    end
  end
end

require 'spec_helper'

describe GithubService do
  let(:project) { create(:project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:pipeline_sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }
  let(:owner) { 'my-user' }
  let(:token) { 'aaaaaaaaa' }
  let(:repository_name) { 'my-project' }
  let(:base_url) { 'https://github.com' }
  let(:repository_url) { "#{base_url}/#{owner}/#{repository_name}" }
  let(:service_params) do
    {
      active: true,
      project: project,
      properties: {
        token: token,
        repository_url: repository_url
      }
    }
  end

  subject { described_class.create(service_params) }

  before do
    stub_licensed_features(github_project_service_integration: true)
  end

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe "#owner" do
    it 'is determined from the repo URL' do
      expect(subject.owner).to eq owner
    end
  end

  describe "#repository_name" do
    it 'is determined from the repo URL' do
      expect(subject.repository_name).to eq repository_name
    end
  end

  describe "#api_url" do
    it 'uses github.com by default' do
      expect(subject.api_url).to eq "https://api.github.com"
    end

    context "with GitHub Enterprise repo URL" do
      let(:base_url) { 'https://my.code-repo.com' }

      it 'is set to the Enterprise API URL' do
        expect(subject.api_url).to eq "https://my.code-repo.com/api/v3"
      end
    end
  end

  describe '#detailed_description' do
    it 'links to mirroring settings' do
      expect(subject.detailed_description).to match(/href=.*mirroring/)
    end
  end

  describe '#execute' do
    let(:remote_repo_path) { "#{owner}/#{repository_name}" }
    let(:sha) { pipeline.sha }
    let(:status_options) { { context: 'security', target_url: 'https://localhost.pipeline.example.com', description: "SAST passed" } }
    let(:status_message) { double(sha: sha, status: :success, status_options: status_options) }
    let(:notifier) { instance_double(GithubService::StatusNotifier) }

    it 'notifies GitHub of a status change' do
      expect(notifier).to receive(:notify)
      expect(GithubService::StatusNotifier).to receive(:new).with(token, remote_repo_path, anything)
                                                            .and_return(notifier)

      subject.execute(pipeline_sample_data)
    end

    it 'uses StatusMessage to build message' do
      allow(subject).to receive(:update_status)

      expect(GithubService::StatusMessage).to receive(:from_pipeline_data).with(project, pipeline_sample_data).and_return(status_message)

      subject.execute(pipeline_sample_data)
    end

    describe 'passes StatusMessage values to StatusNotifier' do
      before do
        allow(GithubService::StatusNotifier).to receive(:new).and_return(notifier)
        allow(GithubService::StatusMessage).to receive(:from_pipeline_data).and_return(status_message)
      end

      specify 'sha' do
        expect(notifier).to receive(:notify).with(sha, anything, anything)

        subject.execute(pipeline_sample_data)
      end

      specify 'status' do
        expected_status = status_message.status
        expect(notifier).to receive(:notify).with(anything, expected_status, anything)

        subject.execute(pipeline_sample_data)
      end

      specify 'context' do
        expected_context = status_options[:context]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(context: expected_context))

        subject.execute(pipeline_sample_data)
      end

      specify 'target_url' do
        expected_target_url = status_options[:target_url]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(target_url: expected_target_url))

        subject.execute(pipeline_sample_data)
      end

      specify 'description' do
        expected_description = status_options[:description]
        expect(notifier).to receive(:notify).with(anything, anything, hash_including(description: expected_description))

        subject.execute(pipeline_sample_data)
      end
    end

    it 'uses GitHub API to update status' do
      github_status_api = "https://api.github.com/repos/#{owner}/#{repository_name}/statuses/#{sha}"
      stub_request(:post, github_status_api)

      subject.execute(pipeline_sample_data)

      expect(a_request(:post, github_status_api)).to have_been_made.once
    end

    context 'with custom api endpoint' do
      let(:api_url) { 'https://my.code.repo' }

      before do
        allow(subject).to receive(:api_url).and_return(api_url)
      end

      it 'hands custom api url to StatusNotifier' do
        allow(notifier).to receive(:notify)
        expect(GithubService::StatusNotifier).to receive(:new).with(anything, anything, api_endpoint: api_url)
                                                              .and_return(notifier)

        subject.execute(pipeline_sample_data)
      end
    end

    context 'without a license' do
      it 'does nothing' do
        stub_licensed_features(github_project_service_integration: false)

        result = subject.execute(pipeline_sample_data)

        expect(result).to be_nil
      end
    end
  end

  describe '#can_test?' do
    it 'is false if there are no pipelines' do
      project.pipelines.delete_all

      expect(subject.can_test?).to eq false
    end

    it 'is true if the project has a pipeline' do
      pipeline

      expect(subject.can_test?).to eq true
    end
  end

  describe '#test_data' do
    let(:user) { project.owner }
    let(:test_data) { subject.test_data(project, user) }

    it 'raises error if no pipeline found' do
      project.pipelines.delete_all

      expect { test_data }.to raise_error 'Please setup a pipeline on your repository.'
    end

    it 'generates data for latest pipeline' do
      pipeline

      expect(test_data[:object_kind]).to eq 'pipeline'
    end
  end

  describe '#test' do
    it 'mentions creator in success message' do
      dummy_response = { context: "default", creator: { login: "YourUser" } }
      allow(subject).to receive(:update_status).and_return(dummy_response)

      result = subject.test(pipeline_sample_data)

      expect(result[:success]).to eq true
      expect(result[:result].to_s).to eq('Status for default updated by YourUser')
    end

    it 'forwards failure message on error' do
      error_response = { method: :post, status: 401, url: 'https://api.github.com/repos/my-user/my-project/statuses/master', body: 'Bad credentials' }
      allow(subject).to receive(:update_status).and_raise(Octokit::Unauthorized, error_response)

      result = subject.test(pipeline_sample_data)

      expect(result[:success]).to eq false
      expect(result[:result].to_s).to end_with('401 - Bad credentials')
    end

    context 'without a license' do
      it 'fails gracefully' do
        stub_licensed_features(github_project_service_integration: false)

        result = subject.test(pipeline_sample_data)

        expect(result[:success]).to eq false
      end
    end
  end
end

require 'spec_helper'

describe GithubService::StatusNotifier do
  let(:access_token) { 'aaaaa' }
  let(:repo_path) { 'myself/my-project' }

  subject { described_class.new(access_token, repo_path) }

  describe '#notify' do
    let(:ref) { 'master' }
    let(:state) { 'pending' }
    let(:params) { { context: 'Gitlab' } }
    let(:github_status_api) { "https://api.github.com/repos/#{repo_path}/statuses/#{ref}" }

    it 'uses GitHub API to update status' do
      stub_request(:post, github_status_api)

      subject.notify(ref, state)

      expect(a_request(:post, github_status_api)).to have_been_made.once
    end

    context 'with blank api_endpoint' do
      let(:api_endpoint) { '' }

      subject { described_class.new(access_token, repo_path, api_endpoint: api_endpoint) }

      it 'defaults to using GitHub.com API' do
        github_status_api = "https://api.github.com/repos/#{repo_path}/statuses/#{ref}"
        stub_request(:post, github_status_api)

        subject.notify(ref, state)

        expect(a_request(:post, github_status_api)).to have_been_made.once
      end
    end

    context 'with custom api_endpoint' do
      let(:api_endpoint) { 'https://my.code.repo' }

      subject { described_class.new(access_token, repo_path, api_endpoint: api_endpoint) }

      it 'uses provided API for requests' do
        custom_status_api = "https://my.code.repo/repos/#{repo_path}/statuses/#{ref}"
        stub_request(:post, custom_status_api)

        subject.notify(ref, state)

        expect(a_request(:post, custom_status_api)).to have_been_made.once
      end
    end

    it 'passes optional params' do
      expect_context = hash_including(context: 'My Context')
      stub_request(:post, github_status_api).with(body: expect_context)

      subject.notify(ref, state, context: 'My Context')
    end

    it 'uses access token' do
      auth_header = { 'Authorization' => 'token aaaaa' }
      stub_request(:post, github_status_api).with(headers: auth_header)

      subject.notify(ref, state)
    end
  end
end

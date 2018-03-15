require 'spec_helper'

describe GithubService::RemoteProject do
  let(:owner) { 'MyUser' }
  let(:repository_name) { 'my-project' }
  let(:repo_full_path) { "#{owner}/#{repository_name}" }
  let(:project_url_base) { "https://github.com/#{repo_full_path}" }
  let(:project_url) { project_url_base }

  subject { described_class.new(project_url) }

  describe '#api_url' do
    it 'uses github.com API endpoint' do
      expect(subject.api_url).to eq 'https://api.github.com'
    end

    context 'when git repo mirror URL is used' do
      let(:project_url) { "https://00000000000000@github.com/#{repo_full_path}.git" }

      it "excludes auth token set as username" do
        expect(subject.api_url).to eq 'https://api.github.com'
      end
    end

    context 'for a custom host' do
      let(:project_url) { "https://my.repo.com/#{repo_full_path}" }

      it 'is extracted from the url' do
        expect(subject.api_url).to eq 'https://my.repo.com/api/v3'
      end
    end
  end

  describe '#owner' do
    it 'is extracted from the url' do
      expect(subject.owner).to eq owner
    end
  end

  describe '#repository_name' do
    it 'is extracted from the url' do
      expect(subject.repository_name).to eq repository_name
    end

    context 'when https git URL is used' do
      let(:project_url) { "#{project_url_base}.git" }

      it "doesn't include '.git' at the end" do
        expect(subject.repository_name).to eq repository_name
      end
    end

    context 'when project sub-route accidentally used' do
      let(:project_url) { "#{project_url_base}/issues" }

      it "ignores the sub-route" do
        expect(subject.repository_name).to eq repository_name
      end
    end
  end
end

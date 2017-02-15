require 'rails_helper'

describe CommitsHelper do
  describe 'commit_author_link' do
    it 'escapes the author email' do
      commit = double(
        author: nil,
        author_name: 'Persistent XSS',
        author_email: 'my@email.com" onmouseover="alert(1)'
      )

      expect(helper.commit_author_link(commit)).
        not_to include('onmouseover="alert(1)"')
    end
  end

  describe 'commit_committer_link' do
    it 'escapes the committer email' do
      commit = double(
        committer: nil,
        committer_name: 'Persistent XSS',
        committer_email: 'my@email.com" onmouseover="alert(1)'
      )

      expect(helper.commit_committer_link(commit)).
        not_to include('onmouseover="alert(1)"')
    end
  end

  describe '#view_on_environment_button' do
    let(:project) { create(:empty_project) }
    let(:environment) { create(:environment, external_url: 'http://example.com') }
    let(:path) { 'source/file.html' }
    let(:sha) { RepoHelpers.sample_commit.id }

    before do
      allow(environment).to receive(:external_url_for).with(path, sha).and_return('http://example.com/file.html')
    end

    it 'returns a link tag linking to the file in the environment' do
      html = helper.view_on_environment_button(sha, path, environment)
      node = Nokogiri::HTML.parse(html).at_css('a')

      expect(node[:title]).to eq('View on example.com')
      expect(node[:href]).to eq('http://example.com/file.html')
    end
  end
end

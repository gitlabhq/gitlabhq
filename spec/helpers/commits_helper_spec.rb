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
end

require 'spec_helper'

feature 'Merge With Push Rules Validation', feature: true, js: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public, push_rule: push_rule) }
  let(:merge_request) { create(:merge_request_with_diffs, source_project: project, author: user, title: 'Bug NS-04') }

  before do
    project.team << [user, :master]
  end

  context 'commit message is invalid' do
    let(:push_rule) { create(:push_rule, :commit_message) }

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'displays error message after merge request is clicked' do
      click_button 'Accept Merge Request'

      expect(page).to have_content('Merge in progress')
      expect(page).to have_content('This merge request failed to be merged automatically')
      expect(page).to have_content("Commit message does not follow the pattern '#{push_rule.commit_message_regex}'")
    end
  end

  context 'author email is invalid' do
    let(:push_rule) { create(:push_rule, :author_email) }

    before do
      login_as user
      visit_merge_request(merge_request)
    end

    it 'displays error message after merge request is clicked' do
      click_button 'Accept Merge Request'

      expect(page).to have_content('Merge in progress')
      expect(page).to have_content('This merge request failed to be merged automatically')
      expect(page).to have_content("Commit author's email '#{user.email}' does not follow the pattern '#{push_rule.author_email_regex}'")
    end
  end

  def visit_merge_request(merge_request)
    visit namespace_project_merge_request_path(merge_request.project.namespace, merge_request.project, merge_request)
  end
end

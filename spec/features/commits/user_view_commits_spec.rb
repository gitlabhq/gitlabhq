# frozen_string_literal: true

require 'spec_helper'

describe 'Commit > User view commits' do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { project.creator }

  before do
    visit project_commits_path(project)
  end

  describe 'Commits List' do
    it 'displays the correct number of commits per day in the header' do
      expect(first('.js-commit-header').find('.commits-count').text).to eq('1 commit')
    end

    it 'lists the correct number of commits' do
      expect(page).to have_selector('#commits-list > li:nth-child(2) > ul', count: 1)
    end
  end
end

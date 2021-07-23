# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create GitLab branches from Jira', :js do
  let_it_be(:alice) { create(:user, name: 'Alice') }
  let_it_be(:bob) { create(:user, name: 'Bob') }

  let_it_be(:project1) { create(:project, :repository, namespace: alice.namespace, title: 'foo') }
  let_it_be(:project2) { create(:project, :repository, namespace: alice.namespace, title: 'bar') }
  let_it_be(:project3) { create(:project, namespace: bob.namespace) }

  let(:source_branch) { 'my-source-branch' }
  let(:new_branch) { 'my-new-branch' }

  before do
    project2.repository.add_branch(alice, source_branch, 'master')
    sign_in(alice)
  end

  def within_dropdown(&block)
    within('.dropdown-menu', &block)
  end

  it 'select project and branch and submit the form' do
    visit new_jira_connect_branch_path(issue_key: 'ACME-123', issue_summary: 'My issue !@#$% title')

    expect(page).to have_field('Branch name', with: 'ACME-123-my-issue-title')
    expect(page).to have_button('Create branch', disabled: true)

    # Select project1

    click_on 'Select a project'

    within_dropdown do
      expect(page).to have_text('Alice / foo')
      expect(page).to have_text('Alice / bar')
      expect(page).not_to have_text('Bob /')

      fill_in 'Search', with: 'foo'

      expect(page).not_to have_text('Alice / bar')

      click_on 'Alice / foo'
    end

    expect(page).to have_button('Create branch', disabled: false)

    click_on 'master'

    within_dropdown do
      fill_in 'Search', with: source_branch

      expect(page).not_to have_text(source_branch)

      fill_in 'Search', with: 'master'

      expect(page).to have_text('master')
    end

    # Switch to project2

    click_on 'Alice / foo'

    within_dropdown do
      fill_in 'Search', with: ''
      click_on 'Alice / bar'
    end

    click_on 'master'

    within_dropdown do
      fill_in 'Search', with: source_branch
      click_on source_branch
    end

    fill_in 'Branch name', with: new_branch
    click_on 'Create branch'

    expect(page).to have_text('New branch was successfully created. You can now close this window and return to Jira.')

    expect(project1.commit(new_branch)).to be_nil
    expect(project2.commit(new_branch)).not_to be_nil
    expect(project2.commit(new_branch)).to eq(project2.commit(source_branch))
  end
end

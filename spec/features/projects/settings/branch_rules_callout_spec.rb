# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Branch rule callout', feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:callout_message) do
    'Edit branch protections, approval rules, and status checks from a single page. ' \
      'How to use branch rules?'
  end

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
    visit project_settings_repository_path(project)
  end

  it 'displays callout on repository settings page' do
    expect(page).to have_content callout_message
    expect(page).to have_link('How to use branch rules',
      href: help_page_path('user/project/repository/branches/branch_rules.md', anchor: 'create-a-branch-rule'))
  end

  context 'when callout is dismissed', :js do
    before do
      find_by_testid('close-branch-rules-callout').click
      wait_for_requests
    end

    it 'does not display callout' do
      expect(page).not_to have_content callout_message
    end
  end
end

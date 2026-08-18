# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User paginates issue designs', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let(:project) { create(:project_empty_repo, :public) }
  let(:issue) { create(:issue, project: project) }

  before do
    enable_design_management
    create_list(:design, 2, :with_file, issue: issue)
    visit project_issue_path(project, issue)
    find('.js-design-list-item', match: :first).click
  end

  it 'paginates to next design' do
    # `have_button(disabled:)` rather than reading the native attribute: these are GlButtons, which
    # signal unavailability with `aria-disabled`. Capybara's filter knows both forms.
    expect(page).to have_button('Go to previous design', disabled: true)

    page.within(find('.js-design-header')) do
      expect(page).to have_content('1 of 2')
    end

    find('.js-next-design').click

    expect(page).to have_button('Go to previous design', disabled: false)

    page.within(find('.js-design-header')) do
      expect(page).to have_content('2 of 2')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issue designs', :js, feature_category: :design_management do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue) }

  before do
    enable_design_management

    visit project_issue_path(project, issue)
  end

  it 'opens design detail' do
    click_link design.filename

    page.within(find('.js-design-header')) do
      expect(page).to have_content(design.filename)
    end

    expect(page).to have_selector('.js-design-image')
  end

  context 'when svg file is loaded in design detail' do
    let_it_be(:file) { Rails.root.join('spec/fixtures/svg_without_attr.svg') }
    let_it_be(:design) { create(:design, :with_file, filename: 'svg_without_attr.svg', file: file, issue: issue) }

    before do
      visit designs_project_issue_path(
        project,
        issue,
        { vueroute: design.filename }
      )
      wait_for_requests
    end

    it 'check if svg is loading' do
      expect(page).to have_selector(
        ".js-design-image > img[alt='svg_without_attr.svg']",
        count: 1,
        visible: :hidden
      )
    end
  end
end

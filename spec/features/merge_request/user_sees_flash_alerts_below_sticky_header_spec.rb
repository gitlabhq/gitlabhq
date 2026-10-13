# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User sees flash alerts below the sticky header', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { project.creator }
  let(:merge_request) { create(:merge_request, source_project: project, author: user) }

  let(:flash_position) do
    "getComputedStyle(document.querySelector('.flash-container.sticky')).position"
  end

  def rect(selector)
    page.evaluate_script(<<~JS)
      (() => {
        const { top, bottom, left, right, width } = document.querySelector('#{selector}').getBoundingClientRect();
        return { top, bottom, left, right, width };
      })()
    JS
  end

  def scroll_panel_to(position)
    page.execute_script("document.querySelector('.js-static-panel-inner').scrollTop = #{position}")
  end

  before do
    sign_in(user)
    # Short enough that the overview scrolls past the sticky header, wide enough for the lg panel styles
    page.current_window.resize_to(1600, 500)
  end

  it 'keeps the flash container in place until the header sticks, then sticks it' do
    visit project_merge_request_path(project, merge_request)

    expect(page).to have_css('.flash-container.sticky.is-sticky-header-observed')
    expect(page).to have_no_css('.flash-container.sticky.is-sticky-header-stuck')
    expect(page.evaluate_script(flash_position)).to eq('relative')

    scroll_panel_to(10000)

    expect(page).to have_css('.flash-container.sticky.is-sticky-header-stuck')
    expect(page.evaluate_script(flash_position)).to eq('sticky')

    # Measure the visible header: the wrapper is taller than it
    flash = rect('.flash-container.sticky')
    expect(flash['top']).to be >= rect('.merge-request-sticky-header')['bottom']
    expect(flash['right']).to be <= rect('.js-right-sidebar')['left']

    scroll_panel_to(0)

    expect(page).to have_no_css('.flash-container.sticky.is-sticky-header-stuck')
    expect(page.evaluate_script(flash_position)).to eq('relative')
  end

  it 'sticks the flash container below the header at full header width on the Changes tab' do
    visit diffs_project_merge_request_path(project, merge_request)

    expect(page).to have_css('.diffs-tab.active')
    expect(page).to have_css('.flash-container.sticky.is-sticky-header-observed')

    scroll_panel_to(10000)

    expect(page).to have_css('.flash-container.sticky.is-sticky-header-stuck')

    flash = rect('.flash-container.sticky')
    header = rect('.merge-request-sticky-header')
    expect(flash['top']).to be >= header['bottom']
    expect(flash['width']).to be_within(1).of(header['width'])
  end

  it 'leaves the flash container sticky on the new merge request page' do
    visit project_new_merge_request_path(project, merge_request: { source_branch: 'feature', target_branch: 'master' })

    # The markdown editor is mounted by the page JS, so the absence check below runs after it
    expect(page).to have_css('[data-testid="markdown-field"]')
    expect(page).to have_no_css('.flash-container.sticky.is-sticky-header-observed')
    expect(page.evaluate_script(flash_position)).to eq('sticky')
  end
end

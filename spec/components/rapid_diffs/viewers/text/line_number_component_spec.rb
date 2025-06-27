# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::LineNumberComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let_it_be(:old_line) { diff_file.diff_lines_with_match_tail.find { |line| line.type == 'old' } }
  let_it_be(:new_line) { diff_file.diff_lines_with_match_tail.find { |line| line.type == 'new' } }
  let_it_be(:meta_line) { diff_file.diff_lines_with_match_tail.find { |line| line.type == 'match' } }
  let(:line_id) { 'line_id' }
  let(:link) { page.find('a') }
  let(:td) { page.find('td') }

  it "renders empty cell without position param" do
    render_component(line: old_line)
    expect(page).to have_selector('td[data-change=removed]')
    expect(page).not_to have_selector('a')
  end

  it "renders empty cell for removed line on right side" do
    render_component(line: old_line, position: :new)
    expect(page).to have_selector('td[data-change=removed]')
    expect(page).not_to have_selector('a')
  end

  it "renders empty cell for added line on left side" do
    render_component(line: new_line, position: :old)
    expect(page).to have_selector('td[data-change=added]')
    expect(page).not_to have_selector('a')
  end

  it "renders empty cell for meta line on right side" do
    render_component(line: meta_line, position: :new)
    expect(page).to have_selector('td[data-change="meta"]')
    expect(page).not_to have_selector('a')
  end

  it "renders empty cell for meta line on left side" do
    render_component(line: meta_line, position: :old)
    expect(page).to have_selector('td[data-change="meta"]')
    expect(page).not_to have_selector('a')
  end

  it "renders link for removed line on left side" do
    render_component(line: old_line, position: :old)
    expect(link.text).to eq('')
    expect(link[:'data-line-number']).to eq(old_line.old_pos.to_s)
    expect(link[:'aria-label']).to eq("Removed line #{old_line.old_pos}")
    expect(link[:href]).to end_with(line_id)
    expect(page).to have_selector('[data-position="old"]')
  end

  it "renders link for added line on right side" do
    render_component(line: new_line, position: :new)
    expect(link.text).to eq('')
    expect(link[:'data-line-number']).to eq(new_line.new_pos.to_s)
    expect(link[:'aria-label']).to eq("Added line #{old_line.new_pos}")
    expect(link[:href]).to end_with(line_id)
    expect(page).to have_selector('[data-position="new"]')
  end

  def render_component(line:, position: nil)
    render_inline(
      described_class.new(
        line: line,
        line_id: line_id,
        position: position
      )
    )
  end
end

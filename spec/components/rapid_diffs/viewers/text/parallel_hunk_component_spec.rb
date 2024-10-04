# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelHunkComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:lines) { diff_file.diff_lines_with_match_tail }
  let(:old_line) { lines.find { |line| line.type == 'old' } }
  let(:new_line) { lines.find { |line| line.type == 'new' } }
  let(:hunk) do
    Gitlab::Diff::ViewerHunk.new(
      header: lines.first,
      lines: lines.drop(1)
    )
  end

  it "renders header" do
    render_component
    expect(page).to have_text(hunk.header_text, count: 2)
  end

  it "renders lines" do
    render_component
    page_text = page.native.inner_html
    hunk.lines.each do |line|
      expect(page_text).to include(line.text_content)
    end
  end

  it "renders line id" do
    old_line_id = old_line.id(diff_file.file_hash, :old)
    new_line_id = new_line.id(diff_file.file_hash, :new)
    render_component
    expect(page).to have_selector("##{old_line_id}")
    expect(page).to have_selector("##{new_line_id}")
  end

  it "renders line link" do
    old_line_id = old_line.id(diff_file.file_hash, :old)
    new_line_id = new_line.id(diff_file.file_hash, :new)
    render_component
    expect(page).to have_selector("a[href='##{old_line_id}']")
    expect(page).to have_selector("a[href='##{new_line_id}']")
  end

  it "renders legacy line id" do
    line_id = diff_file.line_code(old_line)
    render_component
    expect(page).to have_selector("[data-legacy-id='#{line_id}']")
  end

  it "renders expand up" do
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::Line.new("", 'match', 1, 0, 0),
      lines: lines.drop(1)
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
  end

  it "renders expand down" do
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::Line.new("", 'match', 100, 0, 0),
      lines: []
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders both expand up and down" do
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::Line.new("", 'match', 1, 0, 0),
      lines: lines.drop(1),
      prev: Gitlab::Diff::ViewerHunk.new(lines: [])
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders expand both" do
    last_prev_line = lines.first
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: lines.first,
      lines: lines.drop(1),
      prev: Gitlab::Diff::ViewerHunk.new(lines: [last_prev_line])
    )
    allow(diff_hunk.lines.first).to receive(:old_pos).and_return(5)
    allow(last_prev_line).to receive(:old_pos).and_return(2)
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand"]')
  end

  def render_component(diff_hunk = hunk)
    render_inline(described_class.new(diff_file: diff_file, diff_hunk: diff_hunk))
  end
end

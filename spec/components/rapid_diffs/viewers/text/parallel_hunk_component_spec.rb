# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelHunkComponent, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:lines) { diff_file.diff_lines_with_match_tail }
  let(:hunk) { diff_file.viewer_hunks.first }

  it "renders header" do
    render_component
    expect(page).to have_text(hunk.header.text)
  end

  it "renders lines" do
    render_component
    page_text = page.native.inner_html
    hunk.lines.each do |line|
      expect(page_text).to include(line.text_content)
    end
  end

  it "renders line links" do
    render_component
    hunk.parallel_lines.each do |pair|
      line = pair[:left] || pair[:right]
      id = line.id(diff_file.short_file_hash)
      expect(page).to have_selector("a[href='##{id}']")
      expect(page).to have_selector("##{id}")
    end
  end

  it "renders expand up with tooltip" do
    match_line = Gitlab::Diff::Line.new("", 'match', 1, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, nil, 1),
      lines: lines.drop(1)
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button.has-tooltip[title="Show lines before"] svg use[href$="#expand-up"]')
  end

  it "renders expand down with tooltip" do
    match_line = Gitlab::Diff::Line.new("", 'match', 100, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, 1, nil),
      lines: []
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button.has-tooltip[title="Show lines after"] svg use[href$="#expand-down"]')
  end

  it "renders both expand up and down" do
    match_line = Gitlab::Diff::Line.new("", 'match', 1, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, 1, 1),
      lines: lines.drop(1)
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders expand both" do
    match_line = lines.first
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, 1, 10),
      lines: lines.drop(1)
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand"]')
  end

  it "renders testid" do
    render_component
    expect(page).to have_selector("[data-testid='hunk-lines-parallel']")
  end

  it "renders data-hunk-lines" do
    render_component
    expect(page).to have_selector("[data-hunk-lines]")
  end

  it "renders data-hunk-header on header row" do
    render_component
    expect(page).to have_selector("tr[data-hunk-header]")
  end

  it "renders no header row when hunk has no header" do
    diff_hunk = Gitlab::Diff::ViewerHunk.new(lines: hunk.lines)
    render_component(diff_hunk)
    expect(page).not_to have_selector("tr[data-hunk-header]")
  end

  it "renders only the header when lines is nil" do
    match_line = Gitlab::Diff::Line.new("", 'match', 100, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, 1, nil),
      lines: nil
    )
    render_component(diff_hunk)
    expect(page).to have_selector("tr[data-hunk-header]")
    expect(page).not_to have_selector("[data-hunk-lines]")
  end

  it "renders loading spinner inside expand buttons" do
    match_line = Gitlab::Diff::Line.new("", 'match', 100, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(
      header: Gitlab::Diff::ViewerHunkHeader.new(match_line, nil, 1),
      lines: []
    )
    render_component(diff_hunk)
    expect(page).to have_selector('button span[data-visible-when="loading"]')
  end

  it "renders data-expanded when only the right side is expanded" do
    lines.each { |line| line.expanded = false }
    right_line = hunk.parallel_lines.first[:right]
    right_line.expanded = true if right_line
    render_component
    expect(page).to have_selector("[data-expanded]")
  end

  it "renders data-expanded" do
    lines.each { |line| line.expanded = true }
    render_component
    expect(page).to have_selector("[data-expanded]")
  end

  it "renders no line number link or content on old side for added line" do
    added_line = Gitlab::Diff::Line.new("added", 'new', 1, nil, 5)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(lines: [added_line])
    render_component(diff_hunk)
    expect(page).not_to have_selector("td[data-position='old'] a")
    expect(page).not_to have_selector("td[data-position='old'] pre")
    expect(page).to have_selector("td[data-position='new'] a")
    expect(page).to have_selector("td[data-position='new'] pre")
  end

  it "renders no line number link or content on new side for removed line" do
    removed_line = Gitlab::Diff::Line.new("removed", 'old', 1, 5, nil)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(lines: [removed_line])
    render_component(diff_hunk)
    expect(page).to have_selector("td[data-position='old'] a")
    expect(page).to have_selector("td[data-position='old'] pre")
    expect(page).not_to have_selector("td[data-position='new'] a")
    expect(page).not_to have_selector("td[data-position='new'] pre")
  end

  it "renders no line number links for meta lines on both sides" do
    meta_line = Gitlab::Diff::Line.new("@@ -1,3 +1,3 @@", 'match', 1, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(lines: [meta_line])
    render_component(diff_hunk)
    expect(page).not_to have_selector("td[data-position='old'] a")
    expect(page).not_to have_selector("td[data-position='new'] a")
  end

  it "renders span instead of link for zero line number" do
    line = Gitlab::Diff::Line.new("content", nil, 1, 0, 0)
    diff_hunk = Gitlab::Diff::ViewerHunk.new(lines: [line])
    render_component(diff_hunk)
    expect(page).to have_selector("td[data-position] span")
    expect(page).not_to have_selector("td[data-position] a")
  end

  def render_component(diff_hunk = hunk)
    render_inline(
      described_class.new(
        diff_hunk: diff_hunk,
        file_hash: diff_file.short_file_hash
      )
    )
  end
end

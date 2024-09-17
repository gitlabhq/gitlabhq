# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelHunkComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:lines) { diff_file.parallel_diff_lines_with_match_tail }
  let(:hunk) do
    {
      header: lines.first[:left],
      lines: lines.drop(1)
    }
  end

  it "renders header" do
    render_component
    expect(page).to have_text(hunk[:header].text)
  end

  it "renders lines" do
    render_component
    page_text = page.native.inner_html
    hunk[:lines].each do |line_side|
      [line_side[:left], line_side[:right]].compact.each do |line|
        text = line.rich_text || line.text
        expect(page_text).to include(text.gsub(/^[\s+-]/, ''))
      end
    end
  end

  it "renders line id" do
    old_line_id = diff_file.line_side_code(lines.second[:left], :old)
    new_line_id = diff_file.line_side_code(lines.second[:right], :new)
    render_component
    expect(page).to have_selector("##{old_line_id}")
    expect(page).to have_selector("##{new_line_id}")
  end

  it "renders line link" do
    old_line_id = diff_file.line_side_code(lines.second[:left], :old)
    new_line_id = diff_file.line_side_code(lines.second[:right], :new)
    render_component
    expect(page).to have_selector("a[href='##{old_line_id}']")
    expect(page).to have_selector("a[href='##{new_line_id}']")
  end

  it "renders legacy line id" do
    line_id = diff_file.line_code(lines.second[:left])
    render_component
    expect(page).to have_selector("[data-legacy-id='#{line_id}']")
  end

  it "renders expand up" do
    diff_hunk = {
      header: Gitlab::Diff::Line.new("", 'match', 1, 0, 0),
      lines: lines.drop(1)
    }
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
  end

  it "renders expand down" do
    diff_hunk = {
      header: Gitlab::Diff::Line.new("", 'match', 100, 0, 0),
      lines: []
    }
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders both expand up and down" do
    diff_hunk = {
      header: Gitlab::Diff::Line.new("", 'match', 1, 0, 0),
      lines: lines.drop(1),
      prev: { lines: [] }
    }
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders expand both" do
    last_prev_line = lines.first
    diff_hunk = {
      header: lines.first[:left],
      lines: lines.drop(1),
      prev: {
        lines: [last_prev_line]
      }
    }
    allow(diff_hunk[:lines].first[:left]).to receive(:old_pos).and_return(5)
    allow(last_prev_line[:left]).to receive(:old_pos).and_return(2)
    render_component(diff_hunk)
    expect(page).to have_selector('button svg use[href$="#expand"]')
  end

  def render_component(diff_hunk = hunk)
    render_inline(described_class.new(diff_file: diff_file, diff_hunk: diff_hunk))
  end
end

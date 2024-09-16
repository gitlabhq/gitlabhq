# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }
  let(:lines) { diff_file.parallel_diff_lines_with_match_tail }

  it "renders parallel lines" do
    render_component
    expect(page).to have_text(lines.first[:left].rich_text)
    expect(page).to have_text(lines.first[:right].rich_text)
  end

  it "renders headings" do
    render_component
    page_text = page.native.inner_html
    headings = [
      'Original line number',
      'Original line',
      'Diff line number',
      'Diff line'
    ]
    headings.each do |heading|
      expect(page_text).to include(heading)
    end
  end

  def render_component
    render_inline(described_class.new(diff_file: diff_file))
  end
end

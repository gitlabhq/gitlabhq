# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::InlineViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  it "renders inline lines" do
    diff_file.viewer_hunks.each_with_index do |hunk, index|
      allow_next_instances_of(
        RapidDiffs::Viewers::Text::InlineHunkComponent,
        index + 1,
        diff_file: diff_file,
        diff_hunk: hunk
      ) do |instance|
        allow(instance).to receive(:render_in).and_return('hunk-view')
      end
    end
    render_component
    expect(page).to have_text('hunk-view', count: diff_file.viewer_hunks.count)
  end

  it "renders headings" do
    render_component
    page_text = page.native.inner_html
    headings = [
      'Original line number',
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

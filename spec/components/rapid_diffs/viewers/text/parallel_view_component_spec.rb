# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  it "renders parallel lines" do
    diff_file.viewer_hunks.each_with_index do |hunk, index|
      allow_next_instances_of(
        RapidDiffs::Viewers::Text::ParallelHunkComponent,
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
      'Original line',
      'Diff line number',
      'Diff line'
    ]
    headings.each do |heading|
      expect(page_text).to include(heading)
    end
  end

  it "returns virtual row count" do
    instance = described_class.new(diff_file: diff_file)
    render_inline(instance)
    expect(instance.virtual_rendering_params[:total_rows]).to eq(page.find_all('tbody tr').count)
  end

  describe 'row visibility' do
    it "returns 'nil' by default" do
      instance = described_class.new(diff_file: diff_file)
      render_inline(instance)
      expect(instance.virtual_rendering_params[:rows_visibility]).to be_nil
    end

    it "returns 'auto' for large diffs" do
      hunk = Gitlab::Diff::ViewerHunk.new(
        lines: Array.new(Gitlab::Diff::File::ROWS_CONTENT_VISIBILITY_THRESHOLD, diff_file.highlighted_diff_lines.first)
      )
      allow(diff_file).to receive(:viewer_hunks).and_return([hunk])
      instance = described_class.new(diff_file: diff_file)
      render_inline(instance)
      expect(instance.virtual_rendering_params[:rows_visibility]).to eq('auto')
    end
  end

  def render_component
    render_inline(described_class.new(diff_file: diff_file))
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::InlineViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be_with_reload(:diff_file) { build(:diff_file) }

  it "renders table wrapper" do
    render_component
    expect(page).to have_selector('table tbody')
  end

  it "renders headings with a column scope" do
    render_component
    ['Original line number', 'Diff line number', 'Diff line'].each do |heading|
      expect(page).to have_selector("th[scope='col']", text: heading)
    end
  end

  it "renders a screen-reader-only caption summarizing the changes", :aggregate_failures do
    render_component
    expect(page).to have_selector('caption', text: diff_file.file_path)
    expect(page).to have_selector('caption', text: "#{diff_file.added_lines} added line")
    expect(page).to have_selector('caption', text: "#{diff_file.removed_lines} removed line")
  end

  it "returns virtual row count" do
    instance = described_class.new(diff_file: diff_file)
    render_inline(instance)
    expect(instance.virtual_rendering_params[:total_rows]).to eq(page.find_all('tbody tr').count)
  end

  def render_component
    render_inline(described_class.new(diff_file: diff_file))
  end
end

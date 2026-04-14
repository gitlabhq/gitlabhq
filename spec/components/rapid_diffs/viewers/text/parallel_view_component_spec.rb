# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ParallelViewComponent, type: :component, feature_category: :code_review_workflow do
  let_it_be(:diff_file) { build(:diff_file) }

  it "renders table wrapper" do
    render_component
    expect(page).to have_selector('table tbody')
  end

  it "renders headings" do
    render_component
    page_text = page.native.inner_html
    ['Original line number', 'Original line', 'Diff line number', 'Diff line'].each do |heading|
      expect(page_text).to include(heading)
    end
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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::EmptyStateComponent, type: :component, feature_category: :code_review_workflow do
  it "renders with default message" do
    render_inline(described_class.new)
    expect(page).to have_text("There are no changes")
  end

  it "renders with custom message" do
    custom_message = "No changes found in this merge request"
    render_inline(described_class.new(message: custom_message))
    expect(page).to have_text(custom_message)
  end
end

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

  it "renders with a description when provided" do
    render_inline(described_class.new(description: "Some descriptive copy"))
    expect(page).to have_text("Some descriptive copy")
  end

  it "renders a primary button when text and link are provided" do
    render_inline(described_class.new(primary_button_text: "Create commit", primary_button_link: "/new/blob"))

    expect(page).to have_link("Create commit", href: "/new/blob")
  end

  describe "when the primary button is incomplete" do
    where(:case_name, :primary_button_text, :primary_button_link) do
      [
        ["link is missing", "Create commit", nil],
        ["text is missing", nil, "/new/blob"]
      ]
    end

    with_them do
      it "renders no primary button" do
        render_inline(described_class.new(primary_button_text: primary_button_text,
          primary_button_link: primary_button_link))

        expect(page).to have_text("There are no changes")
        expect(page).not_to have_selector("a")
      end
    end
  end
end

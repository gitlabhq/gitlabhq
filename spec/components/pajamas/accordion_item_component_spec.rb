# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::AccordionItemComponent, type: :component, feature_category: :shared do
  let(:title) { "This is a title" }
  let(:content) { "This is the content" }
  let(:button_options) { { class: 'my-class' } }
  let(:state) { :opened }

  before do
    render_inline(described_class.new(title: title, state: state, button_options: button_options)) do |_c|
      content
    end
  end

  describe "title param" do
    it "is shown inside the accordion" do
      expect(page).to have_button(title)
    end
  end

  describe "content" do
    it "is shown inside the accordion" do
      expect(page).to have_css ".accordion-item", text: content
    end
  end

  describe "state (opened) param" do
    it "renders the show class" do
      expect(page).to have_selector('.show')
    end

    it "renders a chevron-down icon" do
      expect(page).to have_selector('[data-testid="chevron-down-icon"]')
    end

    it "renders a button with the correct aria-expanded value" do
      expect(page).to have_selector('button[aria-expanded="true"]')
    end
  end

  describe "state (closed) param" do
    before do
      render_inline(described_class.new(title: title, state: :closed))
    end

    it "does not render the show class" do
      expect(page).not_to have_selector('.show')
    end

    it "renders a chevron-right icon" do
      expect(page).to have_selector('[data-testid="chevron-right-icon"]')
    end

    it "renders a button with the correct aria-expanded value" do
      expect(page).to have_selector('button[aria-expanded="false"]')
    end
  end

  describe "button_options" do
    it "correctly passes options to the button" do
      expect(page).to have_selector('button.my-class')
    end
  end
end

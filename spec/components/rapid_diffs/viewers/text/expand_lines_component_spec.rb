# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ExpandLinesComponent, type: :component, feature_category: :code_review_workflow do
  it "renders expand up" do
    render_component([:up])
    expect(page).to have_selector('button svg use[href$="#expand-up"]')
  end

  it "renders expand down" do
    render_component([:down])
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders expand up and down" do
    render_component([:down, :up])
    expect(page).to have_selector('button svg use[href$="#expand-down"]')
  end

  it "renders expand both" do
    render_component([:both])
    expect(page).to have_selector('button svg use[href$="#expand"]')
  end

  def render_component(directions)
    render_inline(described_class.new(directions: directions))
  end
end

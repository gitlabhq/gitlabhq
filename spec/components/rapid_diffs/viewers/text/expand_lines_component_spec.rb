# frozen_string_literal: true

require "spec_helper"

RSpec.describe RapidDiffs::Viewers::Text::ExpandLinesComponent, type: :component, feature_category: :code_review_workflow do
  let(:expand_up) do
    'button[data-expand-direction="up"][aria-label="Show lines before"] svg use[href$="#expand-up"]'
  end

  let(:expand_down) do
    'button[data-expand-direction="down"][aria-label="Show lines after"] svg use[href$="#expand-down"]'
  end

  let(:expand_both) do
    'button[data-expand-direction="both"][aria-label="Show hidden lines"] svg use[href$="#expand"]'
  end

  it "renders expand up" do
    render_component([:up])
    expect(page).to have_selector(expand_up)
  end

  it "renders expand down" do
    render_component([:down])
    expect(page).to have_selector(expand_down)
  end

  it "renders expand up and down" do
    render_component([:down, :up])
    expect(page).to have_selector(expand_up)
    expect(page).to have_selector(expand_down)
  end

  it "renders expand both" do
    render_component([:both])
    expect(page).to have_selector(expand_both)
  end

  def render_component(directions)
    render_inline(described_class.new(directions: directions))
  end
end

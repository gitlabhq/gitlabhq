# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::AnimatedIconComponent, type: :component, feature_category: :design_system do
  describe "variant param" do
    it 'renders the default "current" variant if none defined' do
      render_inline described_class.new(icon: :chevron_down_up, is_on: false)
      expect(page).to have_selector('.gl-animated-icon-current')
    end

    it 'renders the "info" variant' do
      render_inline described_class.new(icon: :chevron_down_up, variant: :info, is_on: false)
      expect(page).to have_selector('.gl-animated-icon-info')
    end
  end

  describe "is_on param" do
    it "renders the on state" do
      render_inline described_class.new(icon: :chevron_down_up, is_on: true)
      expect(page).to have_selector('.gl-animated-icon-on')
    end

    it "renders the off state" do
      render_inline described_class.new(icon: :chevron_down_up, is_on: false)
      expect(page).to have_selector('.gl-animated-icon-off')
    end
  end

  describe "icon_options param" do
    it 'overrides aria-label' do
      render_inline described_class.new(
        icon: :chevron_down_up,
        is_on: false,
        icon_options: { aria: { label: 'this is a chevron icon' } }
      )
      expect(page).to have_css '[aria-label="this is a chevron icon"]'
    end
  end
end

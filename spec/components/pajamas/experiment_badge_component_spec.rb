# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pajamas::ExperimentBadgeComponent, feature_category: :design_system do
  let(:options) { {} }

  before do
    render_inline(described_class.new(**options))
  end

  describe 'default (experiment) badge' do
    it 'renders an experiment badge' do
      expect(page).to have_css '.gl-badge', text: 'Experiment'
    end

    it 'has a popover with experiment title' do
      expect(page).to have_css '[data-title="What\'s an experiment?"]'
    end

    it 'links to experiment documentation' do
      expect(rendered_content).to include('https://docs.gitlab.com/policy/development_stages_support/#experiment')
    end

    it 'uses bottom placement by default' do
      expect(page).to have_css '[data-placement="bottom"]'
    end

    it 'has hover, focus, and click triggers' do
      expect(page).to have_css '[data-triggers="hover focus click"]'
    end
  end

  describe 'beta badge' do
    let(:options) { { type: :beta } }

    it 'renders a beta badge' do
      expect(page).to have_css '.gl-badge', text: 'Beta'
    end

    it 'has a popover with beta title' do
      expect(page).to have_css '[data-title="What\'s a beta?"]'
    end

    it 'links to beta documentation' do
      expect(rendered_content).to include('https://docs.gitlab.com/policy/development_stages_support/#beta')
    end
  end

  describe 'popover_placement option' do
    let(:options) { { popover_placement: 'top' } }

    it 'uses the specified placement' do
      expect(page).to have_css '[data-placement="top"]'
    end
  end

  describe 'invalid type' do
    let(:options) { { type: :invalid } }

    it 'defaults to experiment' do
      expect(page).to have_css '.gl-badge', text: 'Experiment'
    end
  end
end

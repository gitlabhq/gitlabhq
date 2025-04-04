# frozen_string_literal: true

require "spec_helper"

RSpec.describe Onboarding::ActionCardComponent, type: :component, feature_category: :shared do
  let(:icon) { 'group' }
  let(:title) { 'Create a group' }
  let(:description) { 'Groups are the best way to manage projects and members' }
  let(:href) { nil }
  let(:link_options) { {} }
  let(:html_options) { {} }

  before do
    render_inline described_class.new(icon: icon,
      title: title,
      description: description,
      href: href,
      **link_options,
      **html_options
    )
  end

  describe 'default appearance' do
    it 'has icon' do
      expect(page).to have_css "svg[data-testid='group-icon']"
    end

    it 'has title' do
      expect(page).to have_css ".action-card-title"
    end

    it 'has description' do
      expect(page).to have_css ".action-card-text"
    end
  end

  context 'when link href is defined' do
    let(:href) { 'gitlab.com' }

    it 'has link' do
      expect(page).to have_css ".action-card a"
    end

    it 'has link arrow' do
      expect(page).to have_css ".action-card-arrow[data-testid='arrow-right-icon']"
    end
  end

  context 'with custom card options' do
    let(:html_options) { { data: { testid: 'card_test_id' } } }

    it 'sets the testid' do
      expect(page).to have_selector('.action-card[data-testid="card_test_id"]')
    end
  end

  context 'with custom link options' do
    let(:link_options) { { data: { testid: 'link_test_id' } } }

    it 'sets the testid' do
      expect(page).to have_selector('[data-testid="link_test_id"]')
    end
  end
end

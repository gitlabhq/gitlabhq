# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::SingleStatComponent, type: :component, feature_category: :shared do
  let(:title) { "Single Stat" }
  let(:stat_value) { "9,000" }
  let(:stat_value_testid) { nil }
  let(:title_icon) { nil }
  let(:unit) { nil }
  let(:meta_text) { nil }
  let(:variant) { :success }

  let(:params) do
    {
      title: title,
      title_icon: title_icon,
      stat_value_testid: stat_value_testid,
      stat_value: stat_value,
      unit: unit,
      meta_text: meta_text
    }.compact
  end

  before do
    render_inline(described_class.new(**params))
  end

  context "with default props" do
    it 'shows title' do
      expect(page).to have_css('[data-testid=title-text]', text: title)
    end

    it 'shows stat_value' do
      expect(page).to have_css('[data-testid=non-animated-value]', text: stat_value)
    end

    it 'does not show unit' do
      expect(page).not_to have_css('[data-testid=unit]')
    end

    it 'does not show meta badge' do
      expect(page).not_to have_css('[data-testid=meta-badge]')
    end
  end

  context 'with stat_value_testid' do
    let(:stat_value_testid) { 'foo' }

    it 'shows unique data-testid for stat_value' do
      expect(page).to have_css("[data-testid=#{stat_value_testid}]")
    end
  end

  context "with title_icon" do
    let(:title_icon) { :tanuki }

    it 'shows icon' do
      expect(page).to have_css('svg[data-testid=tanuki-icon]')
    end
  end

  context 'with unit' do
    let(:unit) { 'KB' }

    it 'shows unit' do
      expect(page).to have_css('[data-testid=unit]', text: unit)
    end
  end

  context 'with meta_text' do
    let(:meta_text) { "You're doing great!" }

    it 'shows badge with text' do
      expect(page).to have_css('[data-testid=meta-badge]', text: meta_text)
    end
  end
end

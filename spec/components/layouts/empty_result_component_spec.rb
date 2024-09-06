# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Layouts::EmptyResultComponent, type: :component, feature_category: :shared do
  let(:type) { :search }
  let(:html_options) { { data: { testid: 'empty-result-test-id' } } }

  before do
    render_inline described_class.new(type: type, **html_options)
  end

  it 'renders search empty result' do
    expect(page).to have_css('.gl-empty-state', text: 'No results found')
    expect(page).to have_css('.gl-empty-state', text: 'Edit your search and try again.')
  end

  it 'renders custom attributes' do
    expect(page).to have_css('[data-testid="empty-result-test-id"]')
  end

  context 'when type is filter' do
    let(:type) { :filter }

    it 'renders empty result' do
      expect(page).to have_css('.gl-empty-state', text: 'No results found')
      expect(page).to have_css('.gl-empty-state', text: 'To widen your search, change or remove filters above.')
    end
  end
end

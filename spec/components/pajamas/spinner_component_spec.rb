# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::SpinnerComponent, type: :component do
  let(:options) { {} }

  before do
    render_inline(described_class.new(**options))
  end

  describe 'class' do
    let(:options) { { class: 'gl-my-6' } }

    it 'has the correct custom class' do
      expect(page).to have_css '.gl-spinner-container.gl-my-6'
    end
  end

  describe 'color' do
    context 'by default' do
      it 'is dark' do
        expect(page).to have_css '.gl-spinner.gl-spinner-dark'
      end
    end

    context 'set to light' do
      let(:options) { { color: :light } }

      it 'is light' do
        expect(page).to have_css '.gl-spinner.gl-spinner-light'
      end
    end
  end

  describe 'inline' do
    context 'by default' do
      it 'renders a div' do
        expect(page).to have_css 'div.gl-spinner-container'
      end
    end

    context 'set to true' do
      let(:options) { { inline: true } }

      it 'renders a span' do
        expect(page).to have_css 'span.gl-spinner-container'
      end
    end
  end

  describe 'label' do
    context 'by default' do
      it 'has "Loading" as screen reader available text' do
        expect(page).to have_css('.gl-sr-only', text: 'Loading')
      end
    end

    context 'when set to something else' do
      let(:options) { { label: "Sending" } }

      it 'has a custom label as screen reader available text' do
        expect(page).to have_css('.gl-sr-only', text: 'Sending')
      end
    end
  end

  describe 'size' do
    let(:options) { { size: :lg } }

    it 'has the correct size class' do
      expect(page).to have_css '.gl-spinner.gl-spinner-lg'
    end
  end
end

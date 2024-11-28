# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::PageHeadingComponent, type: :component, feature_category: :shared do
  let(:heading) { 'Page heading' }
  let(:actions) { 'Page actions go here' }
  let(:description) { 'Page description goes here' }

  describe 'slots' do
    it 'renders heading' do
      render_inline described_class.new(heading)

      expect(page).to have_css('h1.gl-heading-1', text: heading)
    end

    it 'renders actions slot' do
      render_inline described_class.new(heading) do |c|
        c.with_actions { actions }
      end

      expect(page).to have_content(actions)
    end

    it 'renders description slot' do
      render_inline described_class.new(heading) do |c|
        c.with_actions { actions }
        c.with_description { description }
      end

      expect(page).to have_css('.gl-w-full.gl-text-subtle', text: description)
    end
  end
end

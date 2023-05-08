# frozen_string_literal: true
require "spec_helper"

RSpec.describe Layouts::HorizontalSectionComponent, type: :component do
  let(:title) { 'Naming, visibility' }
  let(:description) { 'Update your group name, description, avatar, and visibility.' }
  let(:body) { 'This is where the settings go' }

  describe 'slots' do
    it 'renders title' do
      render_inline described_class.new do |c|
        c.with_title { title }
        c.with_body { body }
      end

      expect(page).to have_css('h4', text: title)
    end

    it 'renders body slot' do
      render_inline described_class.new do |c|
        c.with_title { title }
        c.with_body { body }
      end

      expect(page).to have_content(body)
    end

    context 'when description slot is provided' do
      before do
        render_inline described_class.new do |c|
          c.with_title { title }
          c.with_description { description }
          c.with_body { body }
        end
      end

      it 'renders description' do
        expect(page).to have_css('p', text: description)
      end
    end

    context 'when description slot is not provided' do
      before do
        render_inline described_class.new do |c|
          c.with_title { title }
          c.with_body { body }
        end
      end

      it 'does not render description' do
        expect(page).not_to have_css('p', text: description)
      end
    end
  end

  describe 'arguments' do
    describe 'border' do
      it 'defaults to true and adds gl-border-b CSS class' do
        render_inline described_class.new do |c|
          c.with_title { title }
          c.with_body { body }
        end

        expect(page).to have_css('.gl-border-b')
      end

      it 'does not add gl-border-b CSS class when set to false' do
        render_inline described_class.new(border: false) do |c|
          c.with_title { title }
          c.with_body { body }
        end

        expect(page).not_to have_css('.gl-border-b')
      end
    end

    describe 'options' do
      it 'adds options to wrapping element' do
        render_inline described_class.new(options: { data: { testid: 'foo-bar' }, class: 'foo-bar' }) do |c|
          c.with_title { title }
          c.with_body { body }
        end

        expect(page).to have_css('.foo-bar[data-testid="foo-bar"]')
      end
    end
  end
end

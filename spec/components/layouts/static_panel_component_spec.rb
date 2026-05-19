# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Layouts::StaticPanelComponent, feature_category: :design_system do
  include ActionView::Helpers::TagHelper

  let(:component) { described_class.new }

  describe 'html_options' do
    it 'passes html_options to the root element' do
      render_inline described_class.new(html_options: { class: 'custom-class' })

      expect(page).to have_css('.static-panel.custom-class')
    end
  end

  describe 'container_options' do
    it 'passes container_options to the container div' do
      render_inline described_class.new(container_options: { class: 'container-limited' })

      expect(page).to have_css('.container-limited > main')
    end
  end

  describe 'main_options' do
    it 'passes main_options as attributes on the main element' do
      render_inline described_class.new(main_options: { itemscope: true, itemtype: 'https://schema.org/WebPage' })

      expect(page).to have_css('main#content-body[itemscope][itemtype="https://schema.org/WebPage"]')
    end
  end

  describe '.panel-header-inner' do
    context 'when page_breadcrumbs_in_top_bar_feature_flag is true' do
      it 'adds the without-breadcrumbs class' do
        render_inline described_class.new(page_breadcrumbs_in_top_bar_feature_flag: true)

        expect(page).to have_css('.panel-header-inner.without-breadcrumbs')
      end
    end

    context 'when page_breadcrumbs_in_top_bar_feature_flag is false' do
      it 'does not add the without-breadcrumbs class' do
        render_inline described_class.new(page_breadcrumbs_in_top_bar_feature_flag: false)

        expect(page).not_to have_css('.panel-header-inner.without-breadcrumbs')
      end
    end
  end

  describe 'root element' do
    it 'has the js-paneled-view class' do
      render_inline component

      expect(page).to have_css('.paneled-view.js-paneled-view')
    end
  end

  describe 'actions portal target' do
    it 'is always rendered' do
      render_inline component

      expect(page).to have_css('.js-panel-actions-portal-target')
    end
  end

  describe 'slots' do
    it 'renders broadcasts slot inside .broadcast-wrapper' do
      render_inline component do |c|
        c.with_broadcasts { 'Broadcast content' }
      end

      expect(page).to have_css('.broadcast-wrapper', text: 'Broadcast content')
    end

    it 'renders header slot inside the top bar' do
      render_inline component do |c|
        c.with_header { 'Header content' }
      end

      expect(page).to have_css('.panel-header-inner', text: 'Header content')
    end

    it 'renders actions slot inside .panel-header-inner-actions' do
      render_inline component do |c|
        c.with_actions { tag.div(class: 'test-action') }
      end

      expect(page).to have_css('.panel-header-inner-actions .test-action')
    end

    it 'renders before_body slot before the container' do
      render_inline described_class.new(container_options: { class: 'test-container' }) do |c|
        c.with_before_body { tag.div(class: 'test-before-body') }
      end

      expect(page).to have_css('.test-before-body + .test-container')
    end

    it 'renders body slot inside main' do
      render_inline component do |c|
        c.with_body { 'Body content' }
      end

      expect(page).to have_css('main', text: 'Body content')
    end

    it 'renders after_body slot after the container' do
      render_inline described_class.new(container_options: { class: 'test-container' }) do |c|
        c.with_after_body { tag.div(class: 'test-after-body') }
      end

      expect(page).to have_css('.test-container + .test-after-body')
    end

    it 'renders footer slot after .panel-content-inner' do
      render_inline component do |c|
        c.with_footer { tag.div(class: 'test-footer') }
      end

      expect(page).to have_css('.panel-content-inner + .test-footer')
    end
  end
end

# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::AlertComponent, :aggregate_failures, type: :component do
  context 'with content' do
    before do
      render_inline(described_class.new) { '_content_' }
    end

    it 'has content' do
      expect(rendered_component).to have_text('_content_')
    end
  end

  context 'with defaults' do
    before do
      render_inline described_class.new
    end

    it 'does not set a title' do
      expect(rendered_component).not_to have_selector('.gl-alert-title')
      expect(rendered_component).to have_selector('.gl-alert-icon-no-title')
    end

    it 'renders the default variant' do
      expect(rendered_component).to have_selector('.gl-alert-info')
      expect(rendered_component).to have_selector("[data-testid='information-o-icon']")
    end

    it 'renders a dismiss button' do
      expect(rendered_component).to have_selector('.gl-dismiss-btn.js-close')
      expect(rendered_component).to have_selector("[data-testid='close-icon']")
    end
  end

  context 'with custom options' do
    context 'with simple options' do
      context 'without dismissible content' do
        before do
          render_inline described_class.new(
            title: '_title_',
            dismissible: false,
            alert_class: '_alert_class_',
            alert_data: {
              feature_id: '_feature_id_',
              dismiss_endpoint: '_dismiss_endpoint_'
            }
          )
        end

        it 'sets the title' do
          expect(rendered_component).to have_selector('.gl-alert-title')
          expect(rendered_component).to have_content('_title_')
          expect(rendered_component).not_to have_selector('.gl-alert-icon-no-title')
        end

        it 'sets to not be dismissible' do
          expect(rendered_component).not_to have_selector('.gl-dismiss-btn.js-close')
          expect(rendered_component).not_to have_selector("[data-testid='close-icon']")
        end

        it 'sets the alert_class' do
          expect(rendered_component).to have_selector('._alert_class_')
        end

        it 'sets the alert_data' do
          expect(rendered_component).to have_selector('[data-feature-id="_feature_id_"][data-dismiss-endpoint="_dismiss_endpoint_"]')
        end
      end
    end

    context 'with dismissible content' do
      before do
        render_inline described_class.new(
          close_button_class: '_close_button_class_',
          close_button_data: {
            testid: '_close_button_testid_'
          }
        )
      end

      it 'renders a dismiss button and data' do
        expect(rendered_component).to have_selector('.gl-dismiss-btn.js-close._close_button_class_')
        expect(rendered_component).to have_selector("[data-testid='close-icon']")
        expect(rendered_component).to have_selector('[data-testid="_close_button_testid_"]')
      end
    end

    context 'with setting variant type' do
      where(:variant) { [:warning, :success, :danger, :tip] }

      before do
        render_inline described_class.new(variant: variant)
      end

      with_them do
        it 'renders the variant' do
          expect(rendered_component).to have_selector(".gl-alert-#{variant}")
          expect(rendered_component).to have_selector("[data-testid='#{described_class::ICONS[variant]}-icon']")
        end
      end
    end
  end
end

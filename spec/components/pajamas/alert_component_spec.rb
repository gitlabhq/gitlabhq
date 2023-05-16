# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::AlertComponent, :aggregate_failures, type: :component do
  context 'slots' do
    let_it_be(:body) { 'Alert body' }
    let_it_be(:actions) { 'Alert actions' }

    before do
      render_inline described_class.new do |c|
        c.with_body { body }
        c.with_actions { actions }
      end
    end

    it 'renders alert body' do
      expect(page).to have_content(body)
    end

    it 'renders actions' do
      expect(page).to have_content(actions)
    end
  end

  context 'with defaults' do
    before do
      render_inline described_class.new
    end

    it 'does not set a title' do
      expect(page).not_to have_selector('.gl-alert-title')
      expect(page).to have_selector('.gl-alert-icon-no-title')
    end

    it 'renders the default variant' do
      expect(page).to have_selector('.gl-alert-info')
      expect(page).to have_selector("[data-testid='information-o-icon']")
      expect(page).not_to have_selector('.gl-alert-no-icon')
    end

    it 'renders a dismiss button' do
      expect(page).to have_selector('.gl-dismiss-btn.js-close')
      expect(page).to have_selector("[data-testid='close-icon']")
      expect(page).not_to have_selector('.gl-alert-not-dismissible')
    end
  end

  describe 'title' do
    before do
      render_inline described_class.new(title: title)
    end

    context 'with non-empty string' do
      let(:title) { '_title_' }

      it 'sets the title' do
        expect(page).to have_selector('.gl-alert-title')
        expect(page).to have_content(title)
        expect(page).not_to have_selector('.gl-alert-icon-no-title')
      end
    end

    context 'with nil, empty or blank string' do
      where(:title) { [nil, '', '   '] }

      with_them do
        it 'does not set a title' do
          expect(page).not_to have_selector('.gl-alert-title')
          expect(page).to have_selector('.gl-alert-icon-no-title')
        end
      end
    end
  end

  context 'with custom options' do
    context 'with simple options' do
      before do
        render_inline described_class.new(
          alert_options: {
            class: '_alert_class_',
            data: {
              feature_id: '_feature_id_',
              dismiss_endpoint: '_dismiss_endpoint_'
            }
          }
        )
      end

      it 'sets the alert_class' do
        expect(page).to have_selector('._alert_class_')
      end

      it 'sets the alert_data' do
        expect(page).to have_selector('[data-feature-id="_feature_id_"][data-dismiss-endpoint="_dismiss_endpoint_"]')
      end
    end

    context 'with dismissible disabled' do
      before do
        render_inline described_class.new(dismissible: false)
      end

      it 'has the "not dismissible" class' do
        expect(page).to have_selector('.gl-alert-not-dismissible')
      end

      it 'does not render the dismiss button' do
        expect(page).not_to have_selector('.gl-dismiss-btn.js-close')
        expect(page).not_to have_selector("[data-testid='close-icon']")
      end
    end

    context 'with the icon hidden' do
      before do
        render_inline described_class.new(show_icon: false)
      end

      it 'has the hidden icon class' do
        expect(page).to have_selector('.gl-alert-no-icon')
      end

      it 'does not render the icon' do
        expect(page).not_to have_selector('.gl-alert-icon')
        expect(page).not_to have_selector("[data-testid='information-o-icon']")
      end
    end

    context 'with dismissible content' do
      context 'with no custom options' do
        before do
          render_inline described_class.new
        end

        it 'does not have "not dismissible" class' do
          expect(page).not_to have_selector('.gl-alert-not-dismissible')
        end

        it 'renders a dismiss button and data' do
          expect(page).to have_selector('.gl-button.btn-sm.btn-icon.gl-button.gl-dismiss-btn.js-close')
          expect(page).to have_selector("[data-testid='close-icon']")
          expect(page).to have_selector('[aria-label="Dismiss"]')
        end
      end

      context 'with custom options' do
        before do
          render_inline described_class.new(
            close_button_options: {
              aria: {
                label: '_custom_aria_label_'
              },
              class: '_close_button_class_',
              data: {
                testid: '_close_button_testid_',
                "custom-attribute": '_custom_data_'
              }
            }
          )
        end

        it 'renders a dismiss button and data' do
          expect(page).to have_selector('.gl-button.btn-sm.btn-icon.gl-dismiss-btn.js-close._close_button_class_')
          expect(page).to have_selector("[data-testid='close-icon']")
          expect(page).to have_selector('[data-testid="_close_button_testid_"]')
          expect(page).to have_selector('[aria-label="Dismiss"]')
          expect(page).to have_selector('[data-custom-attribute="_custom_data_"]')
        end
      end
    end

    context 'with setting variant type' do
      where(:variant) { [:warning, "success", :danger, "tip"] }

      before do
        render_inline described_class.new(variant: variant)
      end

      with_them do
        it 'renders the variant' do
          expect(page).to have_selector(".gl-alert-#{variant}")
          expect(page).to have_selector("[data-testid='#{described_class::VARIANT_ICONS[variant.to_sym]}-icon']")
        end
      end

      context "with unknown or nil variant" do
        where(:variant) { [:foo, nil] }

        with_them do
          it "adds the default variant class" do
            expect(page).to have_selector(".gl-alert-info")
            expect(page).to have_selector("[data-testid='information-o-icon']")
          end
        end
      end
    end
  end
end

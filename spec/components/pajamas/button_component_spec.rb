# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::ButtonComponent, type: :component, feature_category: :design_system do
  subject do
    described_class.new(**options)
  end

  let(:content) { "Button content" }
  let(:icon_content) { nil }
  let(:options) { {} }

  RSpec.shared_examples 'basic button behavior' do
    before do
      render_inline(subject) do |c|
        c.with_icon_content { icon_content } if icon_content.present?
        content
      end
    end

    it 'renders its content' do
      expect(page).to have_text content
    end

    it 'adds default styling' do
      expect(page).to have_css ".btn.btn-default.btn-md.gl-button"
    end

    describe 'button_options' do
      let(:options) { { button_options: { id: 'baz', data: { foo: 'bar' } } } }

      it 'are added to the button' do
        expect(page).to have_css ".gl-button#baz[data-foo='bar']"
      end

      context 'with custom classes' do
        let(:options) { { variant: :danger, category: :tertiary, button_options: { class: 'custom-class' } } }

        it 'don\'t conflict with internal button_classes' do
          expect(page).to have_css '.gl-button.btn-danger.btn-danger-tertiary.custom-class'
        end
      end

      context 'when overriding base attributes' do
        let(:options) { { button_options: { type: 'submit' } } }

        it 'overrides type' do
          expect(page).to have_css '[type="submit"]'
        end
      end
    end

    describe 'button_text_classes' do
      let(:options) { { button_text_classes: 'custom-text-class' } }

      it 'is added to the button text' do
        expect(page).to have_css ".gl-button-text.custom-text-class"
      end
    end

    describe 'disabled' do
      context 'with defaults (false)' do
        it 'does not have  disabled styling and behavior' do
          expect(page).not_to have_css ".disabled[disabled][aria-disabled]"
        end
      end

      context 'when set to true' do
        let(:options) { { disabled: true } }

        it 'has disabled styling and behavior' do
          expect(page).to have_css ".disabled[disabled][aria-disabled]"
        end
      end
    end

    describe 'loading' do
      context 'with defaults (false)' do
        it 'is not disabled' do
          expect(page).not_to have_css ".disabled[disabled]"
        end

        it 'does not render a spinner' do
          expect(page).not_to have_css('.gl-sr-only', text: 'Loading')
        end
      end

      context 'when set to true' do
        let(:options) { { loading: true } }

        it 'is disabled' do
          expect(page).to have_css ".disabled[disabled]"
        end

        it 'renders a spinner' do
          expect(page).to have_css('.gl-sr-only', text: 'Loading')
        end
      end
    end

    describe 'block' do
      context 'with defaults (false)' do
        it 'is inline' do
          expect(page).not_to have_css ".btn-block"
        end
      end

      context 'when set to true' do
        let(:options) { { block: true } }

        it 'is block element' do
          expect(page).to have_css ".btn-block"
        end
      end
    end

    describe 'label' do
      context 'with defaults (false)' do
        it 'does not render a span with "btn-label" CSS class' do
          expect(page).not_to have_css "span.btn-label"
        end
      end

      context 'when set to true' do
        let(:options) { { label: true } }

        it 'renders a span with "btn-label" CSS class' do
          expect(page).not_to have_css "button[type='button']"
          expect(page).to have_css "span.btn-label"
        end
      end
    end

    describe 'selected' do
      context 'with defaults (false)' do
        it 'does not have selected styling and behavior' do
          expect(page).not_to have_css ".selected"
        end
      end

      context 'when set to true' do
        let(:options) { { selected: true } }

        it 'has selected styling and behavior' do
          expect(page).to have_css ".selected"
        end
      end
    end

    describe 'category & variant' do
      context 'with category variants' do
        where(:variant) { [:default, :confirm, :danger] }

        let(:options) { { variant: variant, category: :tertiary } }

        with_them do
          it 'renders the button in correct variant && category' do
            expect(page).to have_css(".#{described_class::VARIANT_CLASSES[variant]}")
            expect(page).to have_css(".#{described_class::VARIANT_CLASSES[variant]}-tertiary")
          end
        end
      end

      context 'with non-category variants' do
        where(:variant) { [:dashed, :link, :reset] }

        let(:options) { { variant: variant, category: :tertiary } }

        with_them do
          it 'renders the button in correct variant && category' do
            expect(page).to have_css(".#{described_class::VARIANT_CLASSES[variant]}")
            expect(page).not_to have_css(".#{described_class::VARIANT_CLASSES[variant]}-tertiary")
          end
        end
      end

      context 'with primary category' do
        where(:variant) { [:default, :confirm, :danger] }

        let(:options) { { variant: variant, category: :primary } }

        with_them do
          it 'renders the button in correct variant && category' do
            expect(page).to have_css(".#{described_class::VARIANT_CLASSES[variant]}")
            expect(page).not_to have_css(".#{described_class::VARIANT_CLASSES[variant]}-primary")
          end
        end
      end
    end

    describe 'size' do
      context 'with defaults (medium)' do
        it 'applies medium class' do
          expect(page).to have_css ".btn-md"
        end
      end

      context 'when set to small' do
        let(:options) { { size: :small } }

        it 'applies the small class to the button' do
          expect(page).to have_css ".btn-sm"
        end
      end
    end

    describe 'icon' do
      it 'has none by default' do
        expect(page).not_to have_css ".gl-icon"
      end

      context 'with icon' do
        let(:options) { { icon: 'star-o', icon_classes: 'custom-icon' } }

        it 'renders an icon with custom CSS class' do
          expect(page).to have_css "svg.gl-icon.gl-button-icon.custom-icon[data-testid='star-o-icon']"
          expect(page).not_to have_css ".btn-icon"
        end
      end

      context 'with icon only and no content' do
        let(:content) { nil }
        let(:options) { { icon: 'star-o' } }

        it 'adds a "btn-icon" CSS class' do
          expect(page).to have_css ".btn.btn-icon"
        end
      end

      context 'with icon only and when loading' do
        let(:content) { nil }
        let(:options) { { icon: 'star-o', loading: true } }

        it 'renders only a loading icon' do
          expect(page).not_to have_css "svg.gl-icon.gl-button-icon.custom-icon[data-testid='star-o-icon']"
          expect(page).to have_css('.gl-sr-only', text: 'Loading')
        end
      end
    end

    describe 'icon_content' do
      let(:icon_content) { 'Custom icon' }

      it 'renders custom icon content' do
        expect(page).to have_text icon_content
      end
    end
  end

  context 'when button component renders a button' do
    include_examples 'basic button behavior'

    describe 'type' do
      context 'with defaults' do
        it 'has type "button"' do
          expect(page).to have_css "button[type='button']"
        end
      end

      context 'when set to known type' do
        where(:type) { [:button, :reset, :submit] }

        let(:options) { { type: type } }

        with_them do
          it 'has the correct type' do
            expect(page).to have_css "button[type='#{type}']"
          end
        end
      end

      context 'when set to unknown type' do
        let(:options) { { type: :madeup } }

        it 'has type "button"' do
          expect(page).to have_css "button[type='button']"
        end
      end
    end

    context 'when it renders a button_to form' do
      let(:button_options) { { data: { testid: 'button-form' } } }
      let(:options) do
        { href: 'some_post/path', method: :post, form: true, button_options: button_options }
      end

      it 'renders a form' do
        expect(page).to have_css "form[method='post'][action='some_post/path']"
      end

      it 'passes the data attributes to the created button' do
        expect(page).to have_css "button[data-testid='button-form']"
      end

      context 'when params are passed in as a button option' do
        let(:button_options) { { params: { some_param: true } } }

        it 'adds the params to the form as hidden inputs' do
          expect(page).to have_css "input[name='some_param'][value='true']", visible: :hidden
        end
      end
    end
  end

  context 'when button component renders a link' do
    let(:options) { { href: 'https://gitlab.com', target: '_self' } }

    it 'renders a link instead of the button' do
      expect(page).not_to have_css "button[type='button']"
      expect(page).to have_css "a[href='https://gitlab.com'][target='_self']"
    end

    context 'with target="_blank"' do
      let(:options) { { href: 'https://gitlab.com', target: '_blank' } }

      it 'adds rel="noopener noreferrer"' do
        expect(page).to have_css "a[href='https://gitlab.com'][target='_blank'][rel='noopener noreferrer']"
      end

      context 'with a value for "rel" already given' do
        let(:options) { { href: 'https://gitlab.com', target: '_blank', button_options: { rel: 'help next' } } }

        it 'keeps given value and adds "noopener noreferrer"' do
          expect(page).to have_css "a[href='https://gitlab.com'][target='_blank'][rel='help next noopener noreferrer']"
        end
      end

      context 'with "noopener noreferrer" for "rel" already given' do
        let(:options) { { href: 'https://gitlab.com', target: '_blank', button_options: { rel: 'noopener noreferrer' } } }

        it 'does not duplicate "noopener noreferrer"' do
          expect(page).to have_css "a[href='https://gitlab.com'][target='_blank'][rel='noopener noreferrer']"
        end
      end
    end

    include_examples 'basic button behavior'

    describe 'type' do
      let(:options) { { href: 'https://example.com', type: :reset } }

      it 'ignores type' do
        expect(page).not_to have_css "[type]"
      end
    end

    describe 'method' do
      where(:method) { [:get, :post, :put, :delete, :patch] }

      let(:options) { { href: 'https://gitlab.com', method: method } }

      with_them do
        it 'has the correct data-method attribute' do
          expect(page).to have_css "a[data-method='#{method}']"
        end
      end
    end
  end
end

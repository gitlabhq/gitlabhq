# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::BannerComponent, type: :component do
  subject do
    described_class.new(**options)
  end

  let(:title) { "Banner title" }
  let(:content) { "Banner content" }
  let(:options) { {} }

  describe 'basic usage' do
    before do
      render_inline(subject) do |c|
        c.with_title { title }
        content
      end
    end

    it 'renders its content' do
      expect(page).to have_text content
    end

    it 'renders its title' do
      expect(page).to have_css "h2[class='gl-banner-title']", text: title
    end

    it 'renders a close button' do
      expect(page).to have_css "button.gl-button.gl-banner-close"
    end

    describe 'button_text and button_link' do
      let(:options) { { button_text: 'Learn more', button_link: '/learn-more' } }

      it 'define the primary action' do
        expect(page).to have_css "a.btn-confirm.gl-button[href='/learn-more']", text: 'Learn more'
      end
    end

    describe 'banner_options' do
      let(:options) { { banner_options: { class: "baz", data: { foo: "bar" } } } }

      it 'are on the banner' do
        expect(page).to have_css ".gl-banner.baz[data-foo='bar']"
      end

      context 'with custom classes' do
        let(:options) { { variant: :introduction, banner_options: { class: 'extra special' } } }

        it 'don\'t conflict with internal banner_classes' do
          expect(page).to have_css '.extra.special.gl-banner-introduction.gl-banner'
        end
      end
    end

    describe 'close_options' do
      let(:options) { { close_options: { class: "js-foo", data: { uid: "123" } } } }

      it 'are on the close button' do
        expect(page).to have_css "button.gl-banner-close.js-foo[data-uid='123']"
      end
    end

    describe 'variant' do
      context 'by default (promotion)' do
        it 'does not apply introduction class' do
          expect(page).not_to have_css ".gl-banner-introduction"
        end
      end

      context 'when set to introduction' do
        let(:options) { { variant: :introduction } }

        it "applies the introduction class to the banner" do
          expect(page).to have_css ".gl-banner-introduction"
        end

        it "applies the confirm class to the close button" do
          expect(page).to have_css ".gl-banner-close.btn-confirm.btn-confirm-tertiary"
        end
      end

      context 'when set to unknown variant' do
        let(:options) { { variant: :foobar } }

        it 'ignores the unknown variant' do
          expect(page).to have_css ".gl-banner"
        end
      end
    end

    describe 'illustration' do
      it 'has none by default' do
        expect(page).not_to have_css ".gl-banner-illustration"
      end

      context 'with svg_path' do
        let(:options) { { svg_path: 'logo.svg' } }

        it 'renders an image as illustration' do
          expect(page).to have_css ".gl-banner-illustration img"
        end
      end
    end
  end

  context 'with illustration slot' do
    before do
      render_inline(subject) do |c|
        c.with_title { title }
        c.with_illustration { "<svg></svg>".html_safe }
        content
      end
    end

    it 'renders the slot content as illustration' do
      expect(page).to have_css ".gl-banner-illustration svg"
    end

    context 'and conflicting svg_path' do
      let(:options) { { svg_path: 'logo.svg' } }

      it 'uses the slot content' do
        expect(page).to have_css ".gl-banner-illustration svg"
        expect(page).not_to have_css ".gl-banner-illustration img"
      end
    end
  end

  context 'with primary_action slot' do
    before do
      render_inline(subject) do |c|
        c.with_title { title }
        c.with_primary_action { "<a class='special' href='#'>Special</a>".html_safe }
        content
      end
    end

    it 'renders the slot content as the primary action' do
      expect(page).to have_css "a.special", text: 'Special'
    end

    context 'and conflicting button_text and button_link' do
      let(:options) { { button_text: 'Not special', button_link: '/' } }

      it 'uses the slot content' do
        expect(page).to have_css "a.special[href='#']", text: 'Special'
        expect(page).not_to have_css "a.btn[href='/']"
      end
    end
  end
end

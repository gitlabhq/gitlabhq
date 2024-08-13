# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::BadgeComponent, type: :component do
  let(:text) { "Hello" }
  let(:options) { {} }
  let(:html_options) { {} }

  before do
    render_inline(described_class.new(text, **options, **html_options))
  end

  describe "text param" do
    it "is shown inside the badge" do
      expect(page).to have_css ".gl-badge", text: text
    end
  end

  describe "content slot" do
    it "can be used instead of the text param" do
      render_inline(described_class.new) do
        "Slot content"
      end
      expect(page).to have_css ".gl-badge", text: "Slot content"
    end

    it "takes presendence over the text param" do
      render_inline(described_class.new(text)) do
        "Slot wins."
      end
      expect(page).to have_css ".gl-badge", text: "Slot wins."
    end
  end

  describe "options" do
    describe "icon" do
      let(:options) { { icon: :tanuki } }

      it "adds the correct icon and margin" do
        expect(page).to have_css ".gl-icon.gl-badge-icon[data-testid='tanuki-icon']"
      end
    end

    describe "icon_classes" do
      let(:options) { { icon: :tanuki, icon_classes: icon_classes } }

      context "as string" do
        let(:icon_classes) { "js-special-badge-icon js-extra-special" }

        it "combines custom classes and component classes" do
          expect(page).to have_css \
            ".gl-icon.gl-badge-icon.js-special-badge-icon.js-extra-special[data-testid='tanuki-icon']"
        end
      end

      context "as array" do
        let(:icon_classes) { %w[js-special-badge-icon js-extra-special] }

        it "combines custom classes and component classes" do
          expect(page).to have_css \
            ".gl-icon.gl-badge-icon.js-special-badge-icon.js-extra-special[data-testid='tanuki-icon']"
        end
      end
    end

    describe "icon_only" do
      let(:options) { { icon: :tanuki, icon_only: true } }

      it "adds the text as ARIA label" do
        expect(page).to have_css ".gl-badge[aria-label='#{text}'][role='img']"
      end
    end

    describe "href" do
      let(:options) { { href: "/foo" } }

      it "makes the a badge a link" do
        expect(page).to have_link text, class: "gl-badge", href: "/foo"
      end
    end

    describe "variant" do
      where(:variant) { [:muted, :neutral, :info, :success, :warning, :danger] }

      with_them do
        let(:options) { { variant: variant } }

        it "adds variant class" do
          expect(page).to have_css ".gl-badge.badge-#{variant}"
        end
      end

      context "with unknown variant" do
        let(:options) { { variant: :foo } }

        it "adds the default variant class" do
          expect(page).to have_css ".gl-badge.badge-muted"
        end
      end
    end
  end

  describe "HTML options" do
    let(:html_options) { { id: "badge-33", data: { foo: "bar" } } }

    it "get added as HTML attributes" do
      expect(page).to have_css ".gl-badge#badge-33[data-foo='bar']"
    end

    it "can be combined with component options in no particular order" do
      render_inline(described_class.new(text, id: "badge-34", variant: :success, data: { foo: "baz" }))
      expect(page).to have_css ".gl-badge.badge-success#badge-34[data-foo='baz']"
    end

    context "with custom CSS classes" do
      let(:html_options) { { id: "badge-35", class: "js-special-badge" } }

      it "combines custom classes and component classes" do
        expect(page).to have_css ".gl-badge.js-special-badge#badge-35"
      end
    end
  end
end

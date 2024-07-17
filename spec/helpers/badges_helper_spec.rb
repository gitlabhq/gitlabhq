# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BadgesHelper do
  let(:label) { "Test" }

  describe '#gl_badge_tag' do
    it 'creates a badge with given text' do
      expect(helper.gl_badge_tag(label)).to match(%r{<span .*>Test</span>})
    end

    describe 'block content' do
      it 'renders block content' do
        expect(helper.gl_badge_tag { label }).to match(%r{<span .*>Test</span>})
      end

      it 'changes the function signature' do
        options = { variant: :danger }
        html_options = { class: 'foo-bar' }

        tag = helper.gl_badge_tag(label, options, html_options)
        tag_with_block = helper.gl_badge_tag options, html_options do
          label
        end

        expect(tag).to eql(tag_with_block)
      end
    end

    it 'adds style classes' do
      expect(helper.gl_badge_tag(label)).to match(%r{class="gl-badge badge badge-pill badge-muted"})
    end

    it 'adds custom classes' do
      expect(helper.gl_badge_tag(label, nil, class: "test-class")).to match(%r{class=".*test-class.*"})
    end

    describe 'variants' do
      where(:variant) do
        [
          [:muted],
          [:neutral],
          [:info],
          [:success],
          [:warning],
          [:danger]
        ]
      end

      with_them do
        it 'sets the variant class' do
          expected_class = "badge-#{variant}"
          expect(helper.gl_badge_tag(label, variant: variant)).to match(%r{class=".*#{expected_class}.*"})
        end
      end

      it 'defaults to muted' do
        expect(helper.gl_badge_tag(label)).to match(%r{class=".*badge-muted.*"})
      end

      it 'falls back to default given an unknown variant' do
        expect(helper.gl_badge_tag(label, variant: :foo)).to match(%r{class=".*badge-muted.*"})
      end
    end

    it 'applies custom html attributes' do
      expect(helper.gl_badge_tag(label, nil, data: { foo: "bar" })).to match(%r{<span .*data-foo="bar".*>})
    end

    describe 'icons' do
      let(:spacing_class_regex) { %r{<svg .*class=".*my-icon-class".*>.*</svg>} }

      describe 'with text' do
        subject { helper.gl_badge_tag(label, icon: "question-o", icon_classes: 'my-icon-class') }

        it 'renders an icon' do
          expect(subject).to match(%r{<svg .*#question-o".*>.*</svg>})
        end

        it 'adds a spacing class and any custom classes to the icon' do
          expect(subject).to match(spacing_class_regex)
        end
      end

      describe 'icon only' do
        subject { helper.gl_badge_tag(label, icon: 'question-o', icon_only: true) }

        it 'adds an img role to element' do
          expect(subject).to match(%r{<span .*role="img".*>})
        end

        it 'adds aria-label to element' do
          expect(subject).to match(%r{<span .*aria-label="#{label}".*>})
        end

        it 'does not add a spacing class to the icon' do
          expect(subject).not_to match(spacing_class_regex)
        end
      end
    end

    describe 'given an href' do
      it 'creates a badge link' do
        expect(helper.gl_badge_tag(label, nil, href: 'foo')).to match(%r{<a .*href="foo".*>})
      end
    end
  end
end

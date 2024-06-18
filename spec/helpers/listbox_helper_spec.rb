# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ListboxHelper do
  subject do
    tag = helper.gl_redirect_listbox_tag(items, selected, html_options)
    Nokogiri::HTML.fragment(tag).children.first
  end

  before do
    allow(helper).to receive(:sprite_icon).with(
      'chevron-down',
      css_class: 'gl-button-icon gl-new-dropdown-chevron gl-icon'
    ).and_return('<span class="icon"></span>'.html_safe)
  end

  let(:selected) { 'bar' }
  let(:html_options) { {} }
  let(:items) do
    [
      { value: 'foo', text: 'Foo' },
      { value: 'bar', text: 'Bar' }
    ]
  end

  describe '#gl_redirect_listbox_tag' do
    it 'creates root element with expected classes' do
      expect(subject.classes).to include(
        *%w[
          gl-new-dropdown
          js-redirect-listbox
        ])
    end

    it 'sets data attributes for items and selected' do
      expect(subject.attributes['data-items'].value).to eq(items.to_json)
      expect(subject.attributes['data-selected'].value).to eq(selected)
    end

    it 'adds styled button' do
      expect(subject.at_css('button').classes).to include(
        *%w[
          gl-new-dropdown-toggle
        ])
    end

    it 'sets button text to selected item' do
      expect(subject.at_css('button').content.strip).to eq('Bar')
    end

    context 'given html_options' do
      let(:html_options) { { class: 'test-class', data: { qux: 'qux' } } }

      it 'applies them to the root element' do
        expect(subject.attributes['data-qux'].value).to eq('qux')
        expect(subject.classes).to include('test-class')
      end
    end

    context 'when selected does not match any item' do
      where(selected: [nil, 'qux'])

      with_them do
        it 'selects first item' do
          expect(subject.at_css('button').content.strip).to eq('Foo')
          expect(subject.attributes['data-selected'].value).to eq('foo')
        end
      end
    end
  end
end

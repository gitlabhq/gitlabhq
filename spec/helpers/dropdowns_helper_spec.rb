# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DropdownsHelper, feature_category: :design_system do
  before do
    allow(helper).to receive(:sprite_icon).and_return('<span class="icon"></span>'.html_safe)
    allow(helper).to receive(:icon).and_return('<span class="icon"></span>'.html_safe)
  end

  shared_examples 'has two icons' do
    it 'returns two icons' do
      expect(content.scan('icon').count).to eq(2)
    end
  end

  describe '#dropdown_tag' do
    let(:content) { helper.dropdown_tag('toggle', options: { wrapper_class: 'fuz' }) { 'fizzbuzz' } }

    it 'returns the container in the content' do
      expect(content).to include('dropdown fuz')
    end

    it 'returns the block in the content' do
      expect(content).to include('fizzbuzz')
    end
  end

  describe '#dropdown_toggle' do
    let(:content) { helper.dropdown_toggle('foo', { default_label: 'foo' }, { toggle_class: 'fuz' }) }

    it 'returns the button' do
      expect(content).to include('dropdown-menu-toggle fuz')
    end

    it 'returns the buttons default label data attribute' do
      expect(content).to include('data-default-label="foo"')
    end

    it 'returns the dropdown toggle text', :aggregate_failures do
      expect(content).to include('dropdown-toggle-text is-default')
      expect(content).to include('foo')
    end

    it 'returns the button icon in the content' do
      expect(content.scan('icon').count).to eq(1)
    end
  end

  describe '#dropdown_toggle_link' do
    let(:content) { dropdown_toggle_link('foo', { data: 'bar' }, { toggle_class: 'fuz' }) }

    it 'returns the link' do
      expect(content).to include('dropdown-toggle-text fuz')
    end

    it 'returns the links data attribute' do
      expect(content).to include('data-data="bar"')
    end

    it 'returns the link text' do
      expect(content).to include('foo')
    end
  end

  describe '#dropdown_title' do
    shared_examples 'has a back button' do
      it 'contains the back button' do
        expect(content).to include('dropdown-title-button dropdown-menu-back')
      end
    end

    shared_examples 'does not have a back button' do
      it 'does not contain the back button' do
        expect(content).not_to include('dropdown-title-button dropdown-menu-back')
      end
    end

    shared_examples 'does not apply the margin class to the back button' do
      it 'does not contain the back button margin class' do
        expect(content).not_to include('dropdown-title-button dropdown-menu-back gl-mr-auto')
      end
    end

    shared_examples 'has a close button' do
      it 'contains the close button' do
        expect(content).to include('dropdown-title-button dropdown-menu-close')
      end
    end

    shared_examples 'does not have a close button' do
      it 'does not contain the close button' do
        expect(content).not_to include('dropdown-title-button dropdown-menu-close')
      end
    end

    shared_examples 'does not apply the margin class to the close button' do
      it 'does not contain the close button margin class' do
        expect(content).not_to include('dropdown-title-button dropdown-menu-close gl-ml-auto')
      end
    end

    shared_examples 'has the title text' do
      it 'contains the title text' do
        expect(content).to include('Foo')
      end
    end

    shared_examples 'has the title margin class' do |margin_class: ''|
      it 'contains the title margin class' do
        expect(content).to match(/class="#{margin_class}.*"[^>]*>Foo/)
      end
    end

    shared_examples 'does not have the title margin class' do
      it 'does not have the title margin class' do
        expect(content).not_to match(/class="gl-m[r|l]-auto.*"[^>]*>Foo/)
      end
    end

    context 'with a back and close button' do
      let(:content) { helper.dropdown_title('Foo', options: { back: true, close: true }) }

      it 'applies the justification class to the container', :aggregate_failures do
        expect(content).to match(/"dropdown-title.*gl-justify-between"/)
      end

      it_behaves_like 'has a back button'
      it_behaves_like 'has the title text'
      it_behaves_like 'has a close button'
      it_behaves_like 'has two icons'
      it_behaves_like 'does not have the title margin class'
    end

    context 'with a back button' do
      let(:content) { helper.dropdown_title('Foo', options: { back: true, close: false }) }

      it_behaves_like 'has a back button'
      it_behaves_like 'has the title text'
      it_behaves_like 'has the title margin class', margin_class: 'gl-mr-auto'
      it_behaves_like 'does not have a close button'

      it 'returns the back button icon' do
        expect(content.scan('icon').count).to eq(1)
      end
    end

    context 'with a close button' do
      let(:content) { helper.dropdown_title('Foo', options: { back: false, close: true }) }

      it_behaves_like 'does not have a back button'
      it_behaves_like 'has the title text'
      it_behaves_like 'has the title margin class', margin_class: 'gl-ml-auto'
      it_behaves_like 'has a close button'

      it 'returns the close button icon' do
        expect(content.scan('icon').count).to eq(1)
      end
    end

    context 'without any buttons' do
      let(:content) { helper.dropdown_title('Foo', options: { back: false, close: false }) }

      it_behaves_like 'does not have a back button'
      it_behaves_like 'has the title text'
      it_behaves_like 'does not have the title margin class'
      it_behaves_like 'does not have a close button'

      it 'returns no button icons' do
        expect(content.scan('icon').count).to eq(0)
      end
    end
  end

  describe '#dropdown_filter' do
    let(:content) { helper.dropdown_filter('foo') }

    it_behaves_like 'has two icons'

    it 'returns the container' do
      expect(content).to include('dropdown-input')
    end

    it 'returns the search input', :aggregate_failures do
      expect(content).to include('dropdown-input-field')
      expect(content).to include('placeholder="foo"')
    end
  end

  describe '#dropdown_content' do
    shared_examples 'contains the container' do
      it 'returns the container in the content' do
        expect(content).to include('dropdown-content')
      end
    end

    context 'without block' do
      let(:content) { helper.dropdown_content }

      it_behaves_like 'contains the container'
    end

    context 'with block' do
      let(:content) { helper.dropdown_content { 'foo' } }

      it_behaves_like 'contains the container'

      it 'returns the block in the content' do
        expect(content).to include('foo')
      end
    end
  end

  describe '#dropdown_footer' do
    shared_examples 'contains the content' do
      it 'returns the container in the content' do
        expect(content).to include('dropdown-footer')
      end

      it 'returns the block in the content' do
        expect(content).to include('foo')
      end
    end

    context 'without a content class' do
      let(:content) { helper.dropdown_footer { 'foo' } }

      it_behaves_like 'contains the content'
    end

    context 'without a content class' do
      let(:content) { helper.dropdown_footer(add_content_class: true) { 'foo' } }

      it_behaves_like 'contains the content'

      it 'returns the footer in the content' do
        expect(content).to include('dropdown-footer-content')
      end
    end
  end

  describe '#dropdown_loading' do
    let(:content) { helper.dropdown_loading }

    it 'returns the container in the content' do
      expect(content).to include('dropdown-loading')
    end

    it 'returns a gl-spinner in the content' do
      expect(content).to include('gl-spinner')
    end
  end
end

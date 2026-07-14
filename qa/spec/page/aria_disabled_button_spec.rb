# frozen_string_literal: true

RSpec.describe QA::Page::Component::AriaDisabledButton do
  subject(:page_object) do
    Class.new do
      include QA::Page::Component::AriaDisabledButton
    end.new
  end

  describe '#element_disabled?' do
    let(:element_name) { 'some-button' }

    context 'when the element has the native disabled attribute' do
      let(:element) { instance_double(Capybara::Node::Element, disabled?: true) }

      before do
        allow(page_object).to receive(:find_element).with(element_name).and_return(element)
        allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
      end

      it 'returns true' do
        expect(page_object.element_disabled?(element_name)).to be(true)
      end
    end

    context 'when the element has aria-disabled="true"' do
      let(:element) { instance_double(Capybara::Node::Element, disabled?: false, '[]': nil) }

      before do
        allow(page_object).to receive(:find_element).with(element_name).and_return(element)
        allow(element).to receive(:[]).with('aria-disabled').and_return('true')
      end

      it 'returns true' do
        expect(page_object.element_disabled?(element_name)).to be(true)
      end
    end

    context 'when the element has both native disabled and aria-disabled="true"' do
      let(:element) { instance_double(Capybara::Node::Element, disabled?: true, '[]': nil) }

      before do
        allow(page_object).to receive(:find_element).with(element_name).and_return(element)
        allow(element).to receive(:[]).with('aria-disabled').and_return('true')
      end

      it 'returns true' do
        expect(page_object.element_disabled?(element_name)).to be(true)
      end
    end

    context 'when the element is enabled (neither native disabled nor aria-disabled)' do
      let(:element) { instance_double(Capybara::Node::Element, disabled?: false, '[]': nil) }

      before do
        allow(page_object).to receive(:find_element).with(element_name).and_return(element)
        allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
      end

      it 'returns false' do
        expect(page_object.element_disabled?(element_name)).to be(false)
      end
    end

    context 'when the element has aria-disabled="false"' do
      let(:element) { instance_double(Capybara::Node::Element, disabled?: false, '[]': nil) }

      before do
        allow(page_object).to receive(:find_element).with(element_name).and_return(element)
        allow(element).to receive(:[]).with('aria-disabled').and_return('false')
      end

      it 'returns false' do
        expect(page_object.element_disabled?(element_name)).to be(false)
      end
    end
  end
end

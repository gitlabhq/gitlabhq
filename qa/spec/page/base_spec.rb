# frozen_string_literal: true

# rubocop:disable QA/ElementWithPattern
RSpec.describe QA::Page::Base do
  describe 'page helpers' do
    it 'exposes helpful page helpers' do
      expect(subject).to respond_to :refresh, :wait_until, :scroll_to
    end
  end

  describe '.view', 'DSL for defining view partials' do
    subject do
      Class.new(described_class) do
        view 'path/to/some/view.html.haml' do
          element :something, 'string pattern'
          element :something_else, /regexp pattern/
        end

        view 'path/to/some/_partial.html.haml' do
          element :another_element, 'string pattern'
        end
      end
    end

    it 'makes it possible to define page views' do
      expect(subject.views.size).to eq 2
      expect(subject.views).to all(be_an_instance_of(QA::Page::View))
    end

    it 'populates views objects with data about elements' do
      expect(subject.elements.size).to eq 3
      expect(subject.elements).to all(be_an_instance_of(QA::Page::Element))
      expect(subject.elements.map(&:name))
        .to eq [:something, :something_else, :another_element]
    end
  end

  describe '.errors' do
    let(:view) { double('view') }

    context 'when page has views and elements defined' do
      before do
        allow(described_class).to receive(:views)
          .and_return([view])

        allow(view).to receive(:errors).and_return(['some error'])
      end

      it 'iterates views composite and returns errors' do
        expect(described_class.errors).to eq ['some error']
      end
    end

    context 'when page has no views and elements defined' do
      before do
        allow(described_class).to receive(:views).and_return([])
      end

      it 'appends an error about missing views / elements block' do
        expect(described_class.errors)
          .to include 'Page class does not have views / elements defined!'
      end
    end
  end

  describe '#wait_until' do
    subject { Class.new(described_class).new }

    context 'when the condition is true' do
      it 'does not refresh' do
        expect(subject).not_to receive(:refresh)

        subject.wait_until(max_duration: 0.01, raise_on_failure: false) { true }
      end

      it 'returns true' do
        expect(subject.wait_until(max_duration: 0.1, raise_on_failure: false) { true }).to be_truthy
      end
    end

    context 'when the condition is false' do
      it 'refreshes' do
        expect(subject).to receive(:refresh).at_least(:once)

        subject.wait_until(max_duration: 0.01, raise_on_failure: false) { false }
      end

      it 'returns false' do
        allow(subject).to receive(:refresh)

        expect(subject.wait_until(max_duration: 0.01, raise_on_failure: false) { false }).to be_falsey
      end
    end
  end

  describe '#all_elements' do
    before do
      allow(subject).to receive(:all)
      allow(subject).to receive(:wait_for_requests)
    end

    it 'raises an error if count or minimum are not specified' do
      expect { subject.all_elements(:foo) }.to raise_error ArgumentError
    end

    it 'does not raise an error if :minimum, :maximum, :count, or :between is specified' do
      [:minimum, :maximum, :count, :between].each do |param|
        expect { subject.all_elements(:foo, param => 1) }.not_to raise_error
      end
    end
  end

  describe '#has_element?' do
    context 'with disabled: keyword' do
      let(:element) { instance_double(Capybara::Node::Element) }

      before do
        allow(subject).to receive(:wait_for_requests)
        allow(subject).to receive(:find_element).and_return(element)
      end

      context 'when checking disabled: true' do
        context 'and the element has the native disabled attribute' do
          before do
            allow(element).to receive(:disabled?).and_return(true)
            allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
          end

          it 'returns true' do
            expect(subject.has_element?(:foo, disabled: true)).to be(true)
          end
        end

        context 'and the element has aria-disabled="true"' do
          before do
            allow(element).to receive(:disabled?).and_return(false)
            allow(element).to receive(:[]).with('aria-disabled').and_return('true')
          end

          it 'returns true' do
            expect(subject.has_element?(:foo, disabled: true)).to be(true)
          end
        end

        context 'and the element is enabled' do
          before do
            allow(element).to receive(:disabled?).and_return(false)
            allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
          end

          it 'returns false' do
            expect(subject.has_element?(:foo, disabled: true)).to be(false)
          end
        end
      end

      context 'when checking disabled: false' do
        context 'and the element is enabled' do
          before do
            allow(element).to receive(:disabled?).and_return(false)
            allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
          end

          it 'returns true' do
            expect(subject.has_element?(:foo, disabled: false)).to be(true)
          end
        end

        context 'and the element has the native disabled attribute' do
          before do
            allow(element).to receive(:disabled?).and_return(true)
            allow(element).to receive(:[]).with('aria-disabled').and_return(nil)
          end

          it 'returns false' do
            expect(subject.has_element?(:foo, disabled: false)).to be(false)
          end
        end

        context 'and the element has aria-disabled="true"' do
          before do
            allow(element).to receive(:disabled?).and_return(false)
            allow(element).to receive(:[]).with('aria-disabled').and_return('true')
          end

          it 'returns false' do
            expect(subject.has_element?(:foo, disabled: false)).to be(false)
          end
        end
      end
    end
  end

  describe 'reads interrupted by a swapped document' do
    subject(:page) { Class.new(described_class).new }

    let(:swapped_document_error) do
      Selenium::WebDriver::Error::UnknownError.new(
        'unknown error: unhandled inspector error: {"code":-32000,' \
          '"message":"Node with given id does not belong to the document"}'
      )
    end

    let(:max_attempts) { described_class::SWAPPED_DOCUMENT_MAX_ATTEMPTS }

    before do
      allow(page).to receive(:wait_for_requests)
      # The retry sleeps between attempts, which would only slow this suite down
      allow(page).to receive(:sleep)
    end

    describe '#has_element?' do
      it 'retries until the incoming document answers' do
        attempts = 0
        allow(page).to receive(:has_css?) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          true
        end

        expect(page.has_element?(:foo, wait: 0)).to be(true)
        expect(attempts).to eq(max_attempts)
      end

      it 'gives up once the attempts are exhausted' do
        allow(page).to receive(:has_css?).and_raise(swapped_document_error)

        expect { page.has_element?(:foo, wait: 0) }.to raise_error(swapped_document_error)
        expect(page).to have_received(:has_css?).exactly(max_attempts).times
      end

      it 'does not retry an UnknownError raised for any other reason' do
        crash = Selenium::WebDriver::Error::UnknownError.new(
          'unknown error: session deleted because of page crash'
        )
        allow(page).to receive(:has_css?).and_raise(crash)

        expect { page.has_element?(:foo, wait: 0) }.to raise_error(crash)
        expect(page).to have_received(:has_css?).once
      end

      it 'still converts Capybara::ElementNotFound to false without retrying' do
        allow(page).to receive(:has_css?).and_raise(Capybara::ElementNotFound)

        expect(page.has_element?(:foo, wait: 0)).to be(false)
        expect(page).to have_received(:has_css?).once
      end
    end

    describe '#has_no_element?' do
      it 'retries' do
        attempts = 0
        allow(page).to receive(:has_no_css?) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          true
        end

        expect(page.has_no_element?(:foo, wait: 0)).to be(true)
        expect(attempts).to eq(max_attempts)
      end
    end

    describe '#find_element' do
      let(:element) { instance_double(Capybara::Node::Element) }

      it 'retries' do
        attempts = 0
        allow(page).to receive(:find) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          element
        end

        expect(page.find_element(:foo)).to be(element)
        expect(attempts).to eq(max_attempts)
      end
    end

    describe '#all_elements' do
      let(:element) { instance_double(Capybara::Node::Element) }

      it 'retries' do
        attempts = 0
        allow(page).to receive(:all) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          [element]
        end

        expect(page.all_elements(:foo, count: 1)).to eq([element])
        expect(attempts).to eq(max_attempts)
      end
    end

    # #has_text? and #has_no_text? read through Capybara's session rather than the page object,
    # so the transient error has to be raised from there
    describe '#has_text?' do
      let(:capybara_session) { double('Capybara::Session') }

      before do
        allow(page).to receive(:page).and_return(capybara_session)
      end

      it 'retries' do
        attempts = 0
        allow(capybara_session).to receive(:has_text?) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          true
        end

        expect(page.has_text?('some text')).to be(true)
        expect(attempts).to eq(max_attempts)
      end
    end

    describe '#has_no_text?' do
      let(:capybara_session) { double('Capybara::Session') }

      before do
        allow(page).to receive(:page).and_return(capybara_session)
      end

      it 'retries' do
        attempts = 0
        allow(capybara_session).to receive(:has_no_text?) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          true
        end

        expect(page.has_no_text?('some text')).to be(true)
        expect(attempts).to eq(max_attempts)
      end
    end

    describe '#wait_for_gitlab_to_respond' do
      let(:capybara_session) { double('Capybara::Session') }

      before do
        allow(Capybara).to receive(:page).and_return(capybara_session)
      end

      it 'retries' do
        attempts = 0
        allow(capybara_session).to receive(:has_no_text?) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          true
        end

        page.send(:wait_for_gitlab_to_respond)

        expect(attempts).to eq(max_attempts)
      end
    end

    describe '#click_element' do
      let(:element) { instance_double(Capybara::Node::Element, click: nil) }

      it 'retries the lookup without repeating the click' do
        attempts = 0
        allow(page).to receive(:find) do
          attempts += 1
          raise swapped_document_error if attempts < max_attempts

          element
        end

        page.click_element(:foo)

        expect(attempts).to eq(max_attempts)
        expect(element).to have_received(:click).once
      end
    end
  end

  describe 'elements' do
    subject do
      Class.new(described_class) do
        view 'path/to/some/view.html.haml' do
          element :something, required: true
          element :something_else
        end
      end
    end

    describe '#elements' do
      it 'returns all elements' do
        expect(subject.elements.size).to eq(2)
      end
    end

    describe '#required_elements' do
      it 'returns only required elements' do
        expect(subject.required_elements.size).to eq(1)
      end
    end

    describe '#visible?', 'Page is currently visible' do
      let(:page) { subject.new }

      before do
        allow(page).to receive(:wait_for_requests)
      end

      context 'with elements' do
        before do
          allow(page).to receive(:has_no_element?).and_return(has_no_element)
        end

        context 'with element on the page' do
          let(:has_no_element) { false }

          it 'is visible' do
            expect(page).to be_visible
          end

          it 'does not raise error if page has elements' do
            expect { page.visible? }.not_to raise_error
          end
        end

        context 'with element not on the page' do
          let(:has_no_element) { true }

          it 'is not visible' do
            expect(page).not_to be_visible
          end
        end
      end

      context 'with no elements' do
        subject do
          Class.new(described_class) do
            view 'path/to/some/view.html.haml' do
              element :something
              element :something_else
            end
          end
        end

        let(:page) { subject.new }

        it 'raises error if page has no required elements' do
          expect { page.visible? }.to raise_error(described_class::NoRequiredElementsError)
        end
      end
    end
  end
end
# rubocop:enable QA/ElementWithPattern

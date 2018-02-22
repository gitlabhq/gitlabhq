describe QA::Page::Base do
  describe 'page helpers' do
    it 'exposes helpful page helpers' do
      expect(subject).to respond_to :refresh, :wait, :scroll_to
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
      expect(subject.views).to all(be_an_instance_of QA::Page::View)
    end

    it 'populates views objects with data about elements' do
      expect(subject.elements.size).to eq 3
      expect(subject.elements).to all(be_an_instance_of QA::Page::Element)
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
end

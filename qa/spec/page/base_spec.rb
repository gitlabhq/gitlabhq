describe QA::Page::Base do
  describe 'page helpers' do
    it 'exposes helpful page helpers' do
      expect(subject).to respond_to :refresh, :wait, :scroll_to
    end
  end

  describe 'DSL for defining view partials', '.view' do
    subject do
      Class.new(described_class) do
        view 'path/to/some/view.html.haml' do
          element :something, 'string pattern'
          element :something_else, /regexp pattern/
        end

        view 'path/to/some/_partial.html.haml' do
          element :something, 'string pattern'
        end
      end
    end

    it 'makes it possible to define page views' do
      expect(subject.views.size).to eq 2
      expect(subject.views).to all(be_an_instance_of QA::Page::View)
    end

    it 'populates views objects with data about elements' do
      subject.views.first.elements.tap do |elements|
        expect(elements.size).to eq 2
        expect(elements).to all(be_an_instance_of QA::Page::Element)
        expect(elements.map(&:name)).to eq [:something, :something_else]
      end
    end
  end
end

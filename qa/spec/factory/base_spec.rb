describe QA::Factory::Base do
  let(:factory) { spy('factory') }
  let(:product) { spy('product') }

  describe '.fabricate!' do
    subject { Class.new(described_class) }

    before do
      allow(QA::Factory::Product).to receive(:new).and_return(product)
      allow(QA::Factory::Product).to receive(:populate!).and_return(product)
    end

    it 'instantiates the factory and calls factory method' do
      expect(subject).to receive(:new).and_return(factory)

      subject.fabricate!('something')

      expect(factory).to have_received(:fabricate!).with('something')
    end

    it 'returns fabrication product' do
      allow(subject).to receive(:new).and_return(factory)

      result = subject.fabricate!('something')

      expect(result).to eq product
    end

    it 'yields factory before calling factory method' do
      allow(subject).to receive(:new).and_return(factory)

      subject.fabricate! do |factory|
        factory.something!
      end

      expect(factory).to have_received(:something!).ordered
      expect(factory).to have_received(:fabricate!).ordered
    end
  end

  describe '.attribute' do
    subject do
      Class.new(described_class) do
        def fabricate!
          "any"
        end

        # Defined only to be stubbed
        def self.find_page
        end

        attribute :token do
          self.class.find_page.do_something_on_page!
          'resulting value'
        end
      end
    end

    it 'appends new attribute name' do
      expect(subject.attributes_names).to be_one
      expect(subject.attributes_names).to include(:token)
    end

    describe 'populating fabrication product with data' do
      let(:page) { spy('page') }

      before do
        allow(QA::Factory::Product).to receive(:new).and_return(product)
        allow(product).to receive(:page).and_return(page)
        allow(subject).to receive(:find_page).and_return(page)
      end

      it 'populates product after fabrication' do
        subject.fabricate!

        expect(product.token).to eq 'resulting value'
        expect(page).to have_received(:do_something_on_page!)
      end
    end
  end
end

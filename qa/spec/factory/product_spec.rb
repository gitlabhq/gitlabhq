describe QA::Factory::Product do
  let(:factory) do
    Class.new(QA::Factory::Base) do
      def foo
        'bar'
      end
    end.new
  end

  let(:product) { spy('product') }
  let(:product_location) { 'http://product_location' }

  subject { described_class.new(factory, product_location) }

  describe '.populate!' do
    before do
      expect(factory.class).to receive(:attributes).and_return(attributes)
    end

    context 'when the product attribute is populated via a block' do
      let(:attributes) do
        [QA::Factory::Product::Attribute.new(:test, proc { 'returned' })]
      end

      it 'returns a fabrication product and defines factory attributes as its methods' do
        result = described_class.populate!(factory, product_location)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('returned')
      end
    end

    context 'when the product attribute is populated via the api' do
      let(:attributes) do
        [QA::Factory::Product::Attribute.new(:test)]
      end

      it 'returns a fabrication product and defines factory attributes as its methods' do
        expect(factory).to receive(:api_resource).and_return({ test: 'returned' })

        result = described_class.populate!(factory, product_location)

        expect(result).to be_a(described_class)
        expect(result.test).to eq('returned')
      end
    end

    context 'when the product attribute is populated via a factory attribute' do
      let(:attributes) do
        [QA::Factory::Product::Attribute.new(:foo)]
      end

      it 'returns a fabrication product and defines factory attributes as its methods' do
        result = described_class.populate!(factory, product_location)

        expect(result).to be_a(described_class)
        expect(result.foo).to eq('bar')
      end
    end

    context 'when the product attribute has no value' do
      let(:attributes) do
        [QA::Factory::Product::Attribute.new(:bar)]
      end

      it 'returns a fabrication product and defines factory attributes as its methods' do
        expect { described_class.populate!(factory, product_location) }
          .to raise_error(described_class::NoValueError, "No value was computed for product bar of factory #{factory.class.name}.")
      end
    end
  end

  describe '.visit!' do
    it 'makes it possible to visit fabrication product' do
      allow_any_instance_of(described_class)
        .to receive(:visit).and_return('visited some url')

      expect(subject.visit!).to eq 'visited some url'
    end
  end
end

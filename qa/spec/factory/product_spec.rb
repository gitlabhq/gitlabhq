describe QA::Factory::Product do
  let(:factory) { spy('factory') }
  let(:product) { spy('product') }

  describe '.populate!' do
    it 'instantiates and yields factory' do
      expect(described_class).to receive(:new).with(factory)

      described_class.populate!(factory) do |instance|
        instance.something = 'string'
      end

      expect(factory).to have_received(:something=).with('string')
    end

    it 'returns a fabrication product' do
      expect(described_class).to receive(:new)
        .with(factory).and_return(product)

      result = described_class.populate!(factory) do |instance|
        instance.something = 'string'
      end

      expect(result).to be product
    end

    it 'raises unless block given' do
      expect { described_class.populate!(factory) }
        .to raise_error ArgumentError
    end
  end

  describe '.visit!' do
    it 'makes it possible to visit fabrication product' do
      allow_any_instance_of(described_class)
        .to receive(:current_url).and_return('some url')
      allow_any_instance_of(described_class)
        .to receive(:visit).and_return('visited some url')

      expect(described_class.new(factory).visit!)
        .to eq 'visited some url'
    end
  end
end

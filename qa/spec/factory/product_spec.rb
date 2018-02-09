describe QA::Factory::Product do
  let(:factory) { spy('factory') }
  let(:product) { spy('product') }

  describe '.populate!' do
    it 'returns a fabrication product' do
      expect(described_class).to receive(:new).and_return(product)

      result = described_class.populate!(factory) do |instance|
        instance.something = 'string'
      end

      expect(result).to be product
    end
  end

  describe '.visit!' do
    it 'makes it possible to visit fabrication product' do
      allow_any_instance_of(described_class)
        .to receive(:current_url).and_return('some url')
      allow_any_instance_of(described_class)
        .to receive(:visit).and_return('visited some url')

      expect(subject.visit!).to eq 'visited some url'
    end
  end
end

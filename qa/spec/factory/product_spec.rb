describe QA::Factory::Product do
  let(:factory) do
    Class.new(QA::Factory::Base) do
      attribute :test do
        'block'
      end

      attribute :no_block
    end.new
  end

  let(:product) { spy('product') }
  let(:product_location) { 'http://product_location' }

  subject { described_class.new(factory) }

  before do
    factory.web_url = product_location
  end

  describe '.visit!' do
    it 'makes it possible to visit fabrication product' do
      allow_any_instance_of(described_class)
        .to receive(:visit).and_return('visited some url')

      expect(subject.visit!).to eq 'visited some url'
    end
  end
end

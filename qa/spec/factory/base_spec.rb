describe QA::Factory::Base do
  describe '.fabricate!' do
    subject { Class.new(described_class) }
    let(:factory) { spy('factory') }
    let(:product) { spy('product') }

    before do
      allow(QA::Factory::Product).to receive(:new).and_return(product)
    end

    it 'instantiates the factory and calls factory method' do
      expect(subject).to receive(:new).and_return(factory)

      subject.fabricate!('something')

      expect(factory).to have_received(:fabricate!).with('something')
    end

    it 'returns fabrication product' do
      allow(subject).to receive(:new).and_return(factory)
      allow(factory).to receive(:fabricate!).and_return('something')

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

  describe '.dependency' do
    let(:dependency) { spy('dependency') }

    before do
      stub_const('Some::MyDependency', dependency)
    end

    subject do
      Class.new(described_class) do
        dependency Some::MyDependency, as: :mydep do |factory|
          factory.something!
        end
      end
    end

    it 'appends a new dependency and accessors' do
      expect(subject.dependencies).to be_one
    end

    it 'defines dependency accessors' do
      expect(subject.new).to respond_to :mydep, :mydep=
    end
  end

  describe 'building dependencies' do
    let(:dependency) { double('dependency') }
    let(:instance) { spy('instance') }

    subject do
      Class.new(described_class) do
        dependency Some::MyDependency, as: :mydep
      end
    end

    before do
      stub_const('Some::MyDependency', dependency)

      allow(subject).to receive(:new).and_return(instance)
      allow(instance).to receive(:mydep).and_return(nil)
      allow(QA::Factory::Product).to receive(:new)
    end

    it 'builds all dependencies first' do
      expect(dependency).to receive(:fabricate!).once

      subject.fabricate!
    end
  end
end

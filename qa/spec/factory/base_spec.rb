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

    describe 'dependencies fabrication' do
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
        allow(QA::Factory::Product).to receive(:populate!)
      end

      it 'builds all dependencies first' do
        expect(dependency).to receive(:fabricate!).once

        subject.fabricate!
      end
    end
  end

  describe '.product' do
    subject do
      Class.new(described_class) do
        def fabricate!
          "any"
        end

        # Defined only to be stubbed
        def self.find_page
        end

        product :token do
          find_page.do_something_on_page!
          'resulting value'
        end
      end
    end

    it 'appends new product attribute' do
      expect(subject.attributes).to be_one
      expect(subject.attributes).to have_key(:token)
    end

    describe 'populating fabrication product with data' do
      let(:page) { spy('page') }

      before do
        allow(factory).to receive(:class).and_return(subject)
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

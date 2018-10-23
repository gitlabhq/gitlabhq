# frozen_string_literal: true

describe QA::Factory::Base do
  include Support::StubENV

  let(:factory) { spy('factory') }
  let(:product) { spy('product') }
  let(:product_location) { 'http://product_location' }

  shared_context 'fabrication context' do
    subject do
      Class.new(described_class) do
        def self.name
          'MyFactory'
        end
      end
    end

    before do
      allow(subject).to receive(:current_url).and_return(product_location)
      allow(subject).to receive(:new).and_return(factory)
      allow(QA::Factory::Product).to receive(:populate!).with(factory, product_location).and_return(product)
    end
  end

  shared_examples 'fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    it 'yields factory before calling factory method' do
      expect(factory).to receive(:something!).ordered
      expect(factory).to receive(fabrication_method_used).ordered.and_return(product_location)

      subject.public_send(fabrication_method_called, factory: factory) do |factory|
        factory.something!
      end
    end

    it 'does not log the factory and build method when QA_DEBUG=false' do
      stub_env('QA_DEBUG', 'false')
      expect(factory).to receive(fabrication_method_used).and_return(product_location)

      expect { subject.public_send(fabrication_method_called, 'something', factory: factory) }
        .not_to output.to_stdout
    end
  end

  describe '.fabricate!' do
    context 'when factory does not support fabrication via the API' do
      before do
        expect(described_class).to receive(:fabricate_via_api!).and_raise(NotImplementedError)
      end

      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_browser_ui!)

        described_class.fabricate!
      end
    end

    context 'when factory supports fabrication via the API' do
      it 'calls .fabricate_via_browser_ui!' do
        expect(described_class).to receive(:fabricate_via_api!)

        described_class.fabricate!
      end
    end
  end

  describe '.fabricate_via_api!' do
    include_context 'fabrication context'

    it_behaves_like 'fabrication method', :fabricate_via_api!

    it 'instantiates the factory, calls factory method returns fabrication product' do
      expect(factory).to receive(:fabricate_via_api!).and_return(product_location)

      result = subject.fabricate_via_api!(factory: factory, parents: [])

      expect(result).to eq(product)
    end

    it 'logs the factory and build method when QA_DEBUG=true' do
      stub_env('QA_DEBUG', 'true')
      expect(factory).to receive(:fabricate_via_api!).and_return(product_location)

      expect { subject.fabricate_via_api!(factory: factory, parents: []) }
        .to output(/==> Built a MyFactory via api with args \[\] in [\d\w\.\-]+/)
        .to_stdout
    end
  end

  describe '.fabricate_via_browser_ui!' do
    include_context 'fabrication context'

    it_behaves_like 'fabrication method', :fabricate_via_browser_ui!, :fabricate!

    it 'instantiates the factory and calls factory method' do
      subject.fabricate_via_browser_ui!('something', factory: factory, parents: [])

      expect(factory).to have_received(:fabricate!).with('something')
    end

    it 'returns fabrication product' do
      result = subject.fabricate_via_browser_ui!('something', factory: factory, parents: [])

      expect(result).to eq(product)
    end

    it 'logs the factory and build method when QA_DEBUG=true' do
      stub_env('QA_DEBUG', 'true')

      expect { subject.fabricate_via_browser_ui!('something', factory: factory, parents: []) }
        .to output(/==> Built a MyFactory via browser_ui with args \["something"\] in [\d\w\.\-]+/)
        .to_stdout
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
        allow(subject).to receive(:current_url).and_return(product_location)
        allow(instance).to receive(:mydep).and_return(nil)
        expect(QA::Factory::Product).to receive(:populate!)
      end

      it 'builds all dependencies first' do
        expect(dependency).to receive(:fabricate!).once

        subject.fabricate!
      end
    end
  end

  describe '.product' do
    include_context 'fabrication context'

    subject do
      Class.new(described_class) do
        def fabricate!
          "any"
        end

        product :token
      end
    end

    it 'appends new product attribute' do
      expect(subject.attributes).to be_one
      expect(subject.attributes[0]).to be_a(QA::Factory::Product::Attribute)
      expect(subject.attributes[0].name).to eq(:token)
    end
  end
end

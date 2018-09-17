# frozen_string_literal: true

describe QA::Factory::Base do
  include Support::StubENV

  let(:factory) { spy('factory') }
  let(:product) { spy('product') }
  let(:product_location) { 'http://product_location' }

  shared_context 'fabrication context' do
    subject { Class.new(described_class) }

    before do
      allow(QA::Factory::Product).to receive(:new).with(product_location).and_return(product)
      allow(QA::Factory::Product).to receive(:populate!).and_return(product)
      allow(subject).to receive(:current_url).and_return(product_location)
      allow(subject).to receive(:new).and_return(factory)
    end
  end

  shared_examples 'API fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    include_context 'fabrication context'

    it_behaves_like 'fabrication method', fabrication_method_called, actual_fabrication_method

    it 'instantiates the factory and calls factory method' do
      expect(subject).to receive(:new).and_return(factory)

      subject.public_send(fabrication_method_called)

      expect(factory).to have_received(fabrication_method_used)
    end

    it 'returns fabrication product' do
      result = subject.public_send(fabrication_method_called)

      expect(result).to eq product
    end

    it 'logs the factory and build method when VERBOSE=true' do
      stub_env('VERBOSE', 'true')

      expect { subject.public_send(fabrication_method_called) }
        .to output(/Resource #{factory.class.name} built via do_fabricate_via_api/)
        .to_stdout
    end
  end

  shared_examples 'Browser UI fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    include_context 'fabrication context'

    it_behaves_like 'fabrication method', fabrication_method_called, actual_fabrication_method

    it 'instantiates the factory and calls factory method' do
      expect(subject).to receive(:new).and_return(factory)

      subject.public_send(fabrication_method_called, 'something')

      expect(factory).to have_received(fabrication_method_used).with('something')
    end

    it 'returns fabrication product' do
      result = subject.public_send(fabrication_method_called, 'something')

      expect(result).to eq product
    end

    it 'logs the factory and build method when VERBOSE=true' do
      stub_env('VERBOSE', 'true')

      expect { subject.public_send(fabrication_method_called, 'something') }
        .to output(/Resource #{factory.class.name} built via do_fabricate_via_browser_ui/)
        .to_stdout
    end
  end

  shared_examples 'fabrication method' do |fabrication_method_called, actual_fabrication_method = nil|
    let(:fabrication_method_used) { actual_fabrication_method || fabrication_method_called }

    include_context 'fabrication context'

    it 'yields factory before calling factory method' do
      allow(subject).to receive(:new).and_return(factory)

      subject.public_send(fabrication_method_called) do |factory|
        factory.something!
      end

      expect(factory).to have_received(:something!).ordered
      expect(factory).to have_received(fabrication_method_used).ordered
    end

    it 'does not log the factory and build method when VERBOSE=false' do
      stub_env('VERBOSE', 'false')

      expect { subject.public_send(fabrication_method_called, 'something') }
        .not_to output(/Resource #{factory.class.name} built via/)
        .to_stdout
    end
  end

  describe '.fabricate!' do
    context 'when factory does not support fabrication via the API' do
      before do
        allow(factory).to receive(:api_support?).and_return(false)
      end

      it_behaves_like 'Browser UI fabrication method', :fabricate!
    end

    context 'when factory supports fabrication via the API' do
      before do
        allow(factory).to receive(:api_support?).and_return(true)
      end

      it_behaves_like 'API fabrication method', :fabricate!, :fabricate_via_api!
    end
  end

  describe '.fabricate_via_api!' do
    it_behaves_like 'API fabrication method', :fabricate_via_api!
  end

  describe '.fabricate_via_browser_ui!' do
    it_behaves_like 'Browser UI fabrication method', :fabricate_via_browser_ui!, :fabricate!
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
    context 'when the product is produced via the browser' do
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
          allow(QA::Factory::Product).to receive(:new).and_return(product)
          allow(product).to receive(:page).and_return(page)
          allow(subject).to receive(:current_url).and_return(product_location)
          allow(subject).to receive(:find_page).and_return(page)
        end

        it 'populates product after fabrication' do
          subject.fabricate!

          expect(product.token).to eq 'resulting value'
          expect(page).to have_received(:do_something_on_page!)
        end
      end
    end

    context 'when the product is producted via the API' do
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
        expect(subject.attributes).to have_key(:token)
      end

      describe 'populating fabrication product with data' do
        before do
          allow(subject).to receive(:new).and_return(factory)
          allow(factory).to receive(:class).and_return(subject)
          allow(factory).to receive(:api_support?).and_return(true)
          allow(factory).to receive(:api_resource).and_return({ token: 'resulting value' })
          allow(QA::Factory::Product).to receive(:new).and_return(product)
        end

        it 'populates product after fabrication' do
          subject.fabricate!

          expect(product.token).to eq 'resulting value'
        end
      end
    end
  end
end

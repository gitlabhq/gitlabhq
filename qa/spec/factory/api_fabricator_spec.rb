describe QA::Factory::ApiFabricator do
  let(:factory_without_api_support) do
    Class.new do
      def self.name
        'FooBarFactory'
      end
    end
  end

  let(:factory_with_api_support) do
    Class.new do
      def self.name
        'FooBarFactory'
      end

      def api_get_path
        '/foo'
      end

      def api_post_path
        '/bar'
      end

      def api_post_body
        { name: 'John Doe' }
      end
    end
  end

  subject { factory.tap { |f| f.include(described_class) }.new }

  describe '#api_support?' do
    context 'when factory does not respond to api_get_path, api_post_path, and api_post_body' do
      let(:factory) { factory_without_api_support }

      it 'returns false' do
        expect(subject).not_to be_api_support
      end
    end

    context 'when factory responds to api_get_path, api_post_path, and api_post_body' do
      let(:factory) { factory_with_api_support }

      it 'returns true' do
        expect(subject).to be_api_support
      end
    end
  end

  describe '#fabricate_via_api!' do
    context 'when factory does not support fabrication via the API' do
      let(:factory) { factory_without_api_support }

      it 'raises a NotImplementedError exception' do
        expect { subject.fabricate_via_api! }.to raise_error(NotImplementedError, "Factory FooBarFactory does not support fabrication via the API!")
      end
    end

    context 'when factory supports fabrication via the API' do
      let(:factory) { factory_with_api_support }
      let(:api_client) { spy('Runtime::API::Client') }
      let(:api_client_instance) { double('API Client') }
      let(:api_request) { spy('Runtime::API::Request') }
      let(:resource_web_url) { 'http://example.org/api/v4/foo' }
      let(:resource) { { id: 1, name: 'John Doe', web_url: resource_web_url } }
      let(:raw_get) { double('Raw GET response', code: 200, body: resource.to_json) }

      before do
        stub_const('QA::Runtime::API::Client', api_client)
        stub_const('QA::Runtime::API::Request', api_request)

        allow(api_client).to receive(:new).and_return(api_client_instance)
        allow(api_request).to receive(:new).and_return(double(url: resource_web_url))
        allow(subject).to receive(:get).with(resource_web_url).and_return(raw_get)
      end

      context 'when resource already exists' do
        it 'returns the resource URL' do
          expect(api_request).to receive(:new).with(api_client_instance, subject.api_get_path).and_return(double(url: resource_web_url))
          expect(subject).to receive(:get).with(resource_web_url).and_return(raw_get)

          expect(subject.fabricate_via_api!).to eq(resource_web_url)
        end

        it 'populates api_resource with the resource' do
          subject.fabricate_via_api!

          expect(subject.api_resource).to eq(resource)
        end

        context 'when the resource does not expose a `web_url` property' do
          let(:resource) { { id: 1, name: 'John Doe' } }

          it 'raises a ResourceFabricationFailedError exception' do
            expect { subject.fabricate_via_api! }.to raise_error(described_class::ResourceURLMissingError, "API resource for FooBarFactory does not expose a `web_url` property: `#{resource}`.")
            expect(subject.api_resource).to eq(resource)
          end
        end
      end

      context 'when the resource does not exist' do
        let(:raw_get) { double('Raw GET response', code: 404, body: { error: "404 not found." }.to_json) }
        let(:raw_post) { double('Raw POST response', code: 201, body: resource.to_json) }

        before do
          allow(subject).to receive(:post).with(resource_web_url, subject.api_post_body).and_return(raw_post)
        end

        it 'returns the resource URL' do
          expect(api_request).to receive(:new).with(api_client_instance, subject.api_get_path).and_return(double(url: resource_web_url))
          expect(subject).to receive(:get).with(resource_web_url).and_return(raw_get)
          expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body).and_return(raw_post)

          expect(subject.fabricate_via_api!).to eq(resource_web_url)
        end

        it 'populates api_resource with the resource' do
          subject.fabricate_via_api!

          expect(subject.api_resource).to eq(resource)
        end

        context 'when the POST fails' do
          let(:post_response) { { error: "Name already taken." } }
          let(:raw_post) { double('Raw POST response', code: 400, body: post_response.to_json) }

          it 'raises a ResourceFabricationFailedError exception' do
            expect(api_request).to receive(:new).with(api_client_instance, subject.api_get_path).and_return(double(url: resource_web_url))
            expect(subject).to receive(:get).with(resource_web_url).and_return(raw_get)
            expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body).and_return(raw_post)

            expect { subject.fabricate_via_api! }.to raise_error(described_class::ResourceFabricationFailedError, "Fabrication of FooBarFactory using the API failed (400) with `#{post_response}`.")
            expect(subject.api_resource).to be_nil
          end
        end
      end

      context '#transform_api_resource' do
        let(:factory) do
          Class.new do
            def self.name
              'FooBarFactory'
            end

            def api_get_path
              '/foo'
            end

            def api_post_path
              '/bar'
            end

            def api_post_body
              { name: 'John Doe' }
            end

            def transform_api_resource(resource)
              resource[:new] = 'foobar'
              resource
            end
          end
        end

        let(:resource) { { existing: 'foo', web_url: resource_web_url } }
        let(:transformed_resource) { { existing: 'foo', new: 'foobar', web_url: resource_web_url } }

        it 'transforms the resource' do
          expect(subject).to receive(:transform_api_resource).with(resource).and_return(transformed_resource)

          subject.fabricate_via_api!
        end
      end
    end
  end
end

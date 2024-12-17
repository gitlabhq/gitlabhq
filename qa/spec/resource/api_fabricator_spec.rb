# frozen_string_literal: true

RSpec.describe QA::Resource::ApiFabricator do
  let(:resource_without_api_support) do
    Class.new do
      def self.name
        'FooBarResource'
      end
    end
  end

  let(:resource_with_api_support) do
    Class.new do
      def self.name
        'FooBarResource'
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

  let(:graphql_resource) do
    Class.new do
      def self.name
        'FooBarResource'
      end

      def api_get_path
        '/graphql'
      end

      def api_post_path
        api_get_path
      end

      def api_post_body
        <<~GQL
          mutation {
            createFooBar(
              input: {
                name: "name"
              }
            ) {
              name
              id
            }
            errors
          }
        GQL
      end

      def process_api_response(parsed_response)
        response = parsed_response[:foobar]
        response[:id] = extract_graphql_id(response)

        super(response)
      end
    end
  end

  let(:api_client_instance) { QA::Runtime::API::Client.new(personal_access_token: 'foo') }

  before do
    allow(QA::Runtime::User::Store).to receive(:default_api_client).and_return(api_client_instance)
  end

  subject { resource.tap { |f| f.include(described_class) }.new }

  describe '#api_support?' do
    context 'when resource does not support fabrication via the API' do
      let(:resource) { resource_without_api_support }

      it 'returns false' do
        expect(subject).not_to be_api_support
      end
    end

    context 'when resource supports fabrication via the API' do
      let(:resource) { resource_with_api_support }

      it 'returns false' do
        expect(subject).to be_api_support
      end
    end
  end

  describe '#fabricate_via_api!' do
    context 'when resource does not support fabrication via the API' do
      let(:resource) { resource_without_api_support }

      it 'raises a NotImplementedError exception' do
        expect do
          subject.fabricate_via_api!
        end.to raise_error(NotImplementedError, "Resource FooBarResource does not support fabrication via the API!")
      end
    end

    context 'when resource supports fabrication via the API' do
      let(:resource) { resource_with_api_support }
      let(:api_request) { spy('Runtime::API::Request') }
      let(:resource_web_url) { 'http://example.org/api/v4/foo' }
      let(:response) { { id: 1, name: 'John Doe', web_url: resource_web_url } }
      let(:raw_post) { double('Raw POST response', code: 201, body: response.to_json) }

      before do
        stub_const('QA::Runtime::API::Request', api_request)

        allow(api_request).to receive(:new).and_return(double(url: resource_web_url))
        allow(subject).to receive(:get).and_return(double("Raw GET response", code: 200, body: {}.to_json))
      end

      context 'when creating a resource' do
        before do
          allow(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(raw_post)
        end

        it 'returns the resource URL' do
          expect(api_request).to receive(:new).with(api_client_instance,
            subject.api_post_path).and_return(double(url: resource_web_url))
          expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(raw_post)

          expect(subject.fabricate_via_api!).to eq(resource_web_url)
        end

        it 'populates api_resource with the resource' do
          subject.fabricate_via_api!

          expect(subject.api_resource).to eq(response)
        end

        context 'when the POST fails' do
          let(:post_response) { { error: "Name already taken." } }
          let(:raw_post) { double('Raw POST response', code: 400, body: post_response.to_json, headers: {}) }

          it 'raises a ResourceFabricationFailedError exception' do
            expect(api_request).to receive(:new).with(api_client_instance,
              subject.api_post_path).and_return(double(url: resource_web_url))
            expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(raw_post)

            expect { subject.fabricate_via_api! }.to raise_error do |error|
              expect(error.class).to eql(described_class::ResourceFabricationFailedError)
              expect(error.to_s).to eql(<<~ERROR.strip)
                Fabrication of FooBarResource using the API failed (400) with `#{raw_post}`.\n
              ERROR
            end
            expect(subject.api_resource).to be_nil
          end

          it 'logs a correlation id' do
            response = double('Raw POST response', code: 400, body: post_response.to_json,
              headers: { x_request_id: 'foobar' })
            allow(QA::Support::Loglinking).to receive(:logging_environment).and_return(nil)

            expect(api_request).to receive(:new).with(api_client_instance,
              subject.api_post_path).and_return(double(url: resource_web_url))
            expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(response)

            expect { subject.fabricate_via_api! }.to raise_error do |error|
              expect(error.class).to eql(described_class::ResourceFabricationFailedError)
              expect(error.to_s).to eql(<<~ERROR.chomp)
                Fabrication of FooBarResource using the API failed (400) with `#{raw_post}`.
                Correlation Id: foobar
              ERROR
            end
          end

          it 'logs Sentry and Kibana URLs from staging' do
            response = double('Raw POST response', code: 400, body: post_response.to_json,
              headers: { x_request_id: 'foobar' })
            cookies = [{ name: 'Foo', value: 'Bar' }, { name: 'gitlab_canary', value: 'true' }]
            time = Time.new(2022, 11, 14, 0, 0, 0, '+00:00')

            allow(Capybara.current_session).to receive_message_chain(:driver, :browser, :manage,
              :all_cookies).and_return(cookies)
            allow(QA::Runtime::Scenario).to receive(:attributes).and_return({ gitlab_address: 'https://staging.gitlab.com' })
            allow(Time).to receive(:now).and_return(time)

            expect(api_request).to receive(:new).with(api_client_instance,
              subject.api_post_path).and_return(double(url: resource_web_url))
            expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(response)

            expect { subject.fabricate_via_api! }.to raise_error do |error|
              expect(error.class).to eql(described_class::ResourceFabricationFailedError)
              expect(error.to_s).to eql(<<~ERROR.chomp)
                Fabrication of FooBarResource using the API failed (400) with `#{raw_post}`.
                Correlation Id: foobar
                Sentry Url: https://new-sentry.gitlab.net/organizations/gitlab/issues/?environment=gstg&project=3&query=correlation_id%3A%22foobar%22
                Kibana - Discover Url: https://nonprod-log.gitlab.net/app/discover#/?_a=%28index:%27ed942d00-5186-11ea-ad8a-f3610a492295%27%2Cquery%3A%28language%3Akuery%2Cquery%3A%27json.correlation_id%20%3A%20foobar%27%29%29&_g=%28time%3A%28from%3A%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29
                Kibana - Dashboard Url: https://nonprod-log.gitlab.net/app/dashboards#/view/b74dc030-6f56-11ed-9af2-6131f0ee4ce6?_g=%28time%3A%28from:%272022-11-13T00:00:00.000Z%27%2Cto%3A%272022-11-14T00:00:00.000Z%27%29%29&_a=%28filters%3A%21%28%28query%3A%28match_phrase%3A%28json.correlation_id%3A%27foobar%27%29%29%29%29%29
              ERROR
            end
          end
        end
      end

      describe '#transform_api_resource' do
        let(:resource) do
          Class.new do
            def self.name
              'FooBarResource'
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

        let(:response) { { existing: 'foo', web_url: resource_web_url } }
        let(:transformed_resource) { { existing: 'foo', new: 'foobar', web_url: resource_web_url } }

        it 'transforms the resource' do
          expect(subject).to receive(:post).with(resource_web_url, subject.api_post_body, {}).and_return(raw_post)
          expect(subject).to receive(:transform_api_resource).with(response).and_return(transformed_resource)

          subject.fabricate_via_api!
        end
      end
    end

    context 'when graphql resource supports fabrication via the API' do
      let(:resource) { graphql_resource }
      let(:api_request) { spy('Runtime::API::Request') }
      let(:resource_web_url) { 'http://example.org/api/v4/foo' }
      let(:response) do
        {
          data: {
            foobarCreate: {
              foobar: {
                id: "gid://gitlab/FooBar/4096",
                title: "testing 1",
                dueDate: "2024-08-11",
                webUrl: resource_web_url
              },
              errors: []
            }
          }
        }
      end

      let(:parsed_resource) do
        {
          id: "4096",
          title: "testing 1",
          due_date: "2024-08-11",
          web_url: resource_web_url
        }
      end

      let(:raw_post) { double('Raw POST response', code: 200, body: response.to_json) }

      before do
        stub_const('QA::Runtime::API::Request', api_request)

        allow(api_request).to receive(:new).and_return(double(url: resource_web_url))
        allow(subject).to receive(:get).and_return(double("Raw GET response", code: 200, body: {}.to_json))
      end

      context 'when creating a resource' do
        before do
          allow(subject).to receive(:post).with(resource_web_url, { query: subject.api_post_body }, {})
            .and_return(raw_post)
        end

        it 'returns the resource URL' do
          expect(api_request).to receive(:new).with(api_client_instance, subject.api_post_path)
            .and_return(double(url: resource_web_url))
          expect(subject).to receive(:post).with(resource_web_url, { query: subject.api_post_body }, {})
            .and_return(raw_post)

          expect(subject.fabricate_via_api!).to eq(resource_web_url)
        end

        it 'populates api_resource with the extracted graphql body' do
          subject.fabricate_via_api!

          expect(subject.api_resource).to eq(parsed_resource)
        end
      end
    end
  end

  describe '#exists?' do
    let(:resource) { resource_with_api_support }
    let(:request) { double('GET request', url: 'new-url') }
    let(:args) { { max_redirects: 0 } }

    before do
      allow(QA::Runtime::API::Request).to receive(:new).and_return(request)
    end

    context 'when request is successful' do
      let(:response) { double('GET response', code: 200) }

      it 'returns true' do
        expect(subject).to receive(:get).with(request.url, args).and_return(response)

        expect(subject.exists?(**args)).to eq(true)
      end
    end

    context 'when request is unsuccessful' do
      let(:response) { double('GET response', code: 404) }

      it 'returns false' do
        expect(subject).to receive(:get).with(request.url, args).and_return(response)

        expect(subject.exists?(**args)).to eq(false)
      end
    end
  end
end

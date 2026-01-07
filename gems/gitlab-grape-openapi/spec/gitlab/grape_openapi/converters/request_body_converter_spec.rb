# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Converters::RequestBodyConverter do
  let(:method) { 'POST' }
  let(:route_path) { "/api/v1/users/:id" }
  let(:params) { {} }
  let(:body_params) { {} }
  let(:options) { { method: method, params: params } }

  let(:route) do
    double('Route', path: route_path)
  end

  let(:parameters_instance) { instance_double(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters) }
  let(:parameter_schema_instance) { instance_double(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema) }

  subject(:request_body) do
    described_class.convert(route: route, options: options, params: params)
  end

  before do
    allow(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters)
      .to receive(:new)
      .with(route: route, params: params)
      .and_return(parameters_instance)

    allow(parameters_instance).to receive(:extract).and_return(body_params)

    allow(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema)
      .to receive(:new)
      .with(route: route)
      .and_return(parameter_schema_instance)
  end

  describe '.convert' do
    describe 'HTTP method handling' do
      let(:params) { { name: {} } }
      let(:body_params) do
        { name: { type: 'String', desc: 'User name', required: true } }
      end

      before do
        allow(parameter_schema_instance)
          .to receive(:build)
          .with(:name, body_params[:name])
          .and_return({ type: 'string', description: 'User name' })
      end

      context 'with GET request' do
        let(:method) { 'GET' }

        it 'returns nil' do
          expect(request_body).to be_nil
        end

        it 'does not call Parameters' do
          request_body
          expect(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters).not_to have_received(:new)
        end

        it 'does not call ParameterSchema' do
          request_body
          expect(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema).not_to have_received(:new)
        end
      end

      context 'with DELETE request' do
        let(:method) { 'DELETE' }

        it 'returns nil' do
          expect(request_body).to be_nil
        end

        it 'does not call Parameters' do
          request_body
          expect(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters).not_to have_received(:new)
        end

        it 'does not call ParameterSchema' do
          request_body
          expect(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema).not_to have_received(:new)
        end
      end

      %w[POST PUT PATCH].each do |http_method|
        context "with #{http_method} request" do
          let(:method) { http_method }

          it 'generates request body' do
            expect(request_body).not_to be_nil
            expect(request_body).to have_key(:content)
          end

          it 'calls ParameterSchema for each body param' do
            request_body
            expect(parameter_schema_instance).to have_received(:build).with(:name, body_params[:name])
          end
        end
      end

      %w[HEAD OPTIONS].each do |http_method|
        context "with #{http_method} request" do
          let(:method) { http_method }

          it 'generates request body' do
            expect(request_body).not_to be_nil
            expect(request_body).to have_key(:content)
          end
        end
      end
    end

    context 'with empty params' do
      let(:method) { 'POST' }
      let(:params) { {} }

      it 'returns nil' do
        expect(request_body).to be_nil
      end

      it 'does not call Parameters' do
        request_body
        expect(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters).not_to have_received(:new)
      end

      it 'does not call ParameterSchema' do
        request_body
        expect(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema).not_to have_received(:new)
      end
    end

    context 'when Parameters returns empty body params' do
      let(:method) { 'POST' }
      let(:params) { { id: { type: 'String', required: true } } }
      let(:body_params) { {} }

      it 'returns nil' do
        expect(request_body).to be_nil
      end

      it 'does not call ParameterSchema' do
        request_body
        expect(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema).not_to have_received(:new)
      end
    end

    context 'with body parameters' do
      let(:method) { 'POST' }
      let(:params) { { name: {}, email: {} } }
      let(:body_params) do
        {
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      before do
        allow(parameter_schema_instance)
          .to receive(:build)
          .with(:name, body_params[:name])
          .and_return({ type: 'string', description: 'User name' })

        allow(parameter_schema_instance)
          .to receive(:build)
          .with(:email, body_params[:email])
          .and_return({ type: 'string', description: 'User email' })

        allow(parameter_schema_instance)
          .to receive(:build)
          .with(:file, body_params[:file])
          .and_return({ type: 'string', format: 'binary', description: 'User email' })
      end

      it 'returns a request body hash' do
        expect(request_body).to be_a(Hash)
        expect(request_body).to have_key(:required)
        expect(request_body).to have_key(:content)
      end

      it 'sets required to true when required parameters exist' do
        expect(request_body[:required]).to be(true)
      end

      it 'includes application/json content type' do
        expect(request_body[:content]).to have_key('application/json')
      end

      context 'when the endpoint allows file uploads' do
        let(:body_params) do
          {
            name: { type: 'String', desc: 'User name', required: true },
            email: { type: 'String', desc: 'User email', required: false },
            file: { type: 'API::Validations::Types::WorkhorseFile', desc: 'User profile picture', required: false }
          }
        end

        it 'includes multipart/form-data content type' do
          expect(request_body[:content]).to have_key('multipart/form-data')
        end
      end

      context 'when the endpoint allows file uploads in multiple ways' do
        let(:body_params) do
          {
            name: { type: 'String', desc: 'User name', required: true },
            email: { type: 'String', desc: 'User email', required: false },
            file: {
              type: %w[API::Validations::Types::WorkhorseFile Rack::Multipart::UploadedFile],
              desc: 'User profile picture',
              required: true
            }
          }
        end

        it 'includes multipart/form-data content type' do
          expect(request_body[:content]).to have_key('multipart/form-data')
        end
      end

      it 'includes schema with object type' do
        schema = request_body[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
      end

      it 'includes properties for all body parameters' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties).to have_key('name')
        expect(properties).to have_key('email')
      end

      it 'marks required parameters in schema' do
        schema = request_body[:content]['application/json'][:schema]
        expect(schema[:required]).to include('name')
        expect(schema[:required]).not_to include('email')
      end

      it 'calls ParameterSchema for each body param' do
        request_body
        expect(parameter_schema_instance).to have_received(:build).with(:name, body_params[:name])
        expect(parameter_schema_instance).to have_received(:build).with(:email, body_params[:email])
      end

      it 'uses schema returned by ParameterSchema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['name']).to eq({ type: 'string', description: 'User name' })
        expect(properties['email']).to eq({ type: 'string', description: 'User email' })
      end
    end

    context 'with all optional body parameters' do
      let(:method) { 'POST' }
      let(:params) { { name: {}, email: {} } }
      let(:body_params) do
        {
          name: { type: 'String', desc: 'User name', required: false },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      before do
        allow(parameter_schema_instance)
          .to receive(:build)
          .and_return({ type: 'string' })
      end

      it 'sets required to false' do
        expect(request_body[:required]).to be(false)
      end

      it 'does not include required array in schema when empty' do
        schema = request_body[:content]['application/json'][:schema]
        expect(schema).not_to have_key(:required)
      end
    end

    context 'with symbols as parameter keys' do
      let(:params) { { name: {} } }
      let(:body_params) do
        { name: { type: 'String', desc: 'User name', required: true } }
      end

      before do
        allow(parameter_schema_instance)
          .to receive(:build)
          .with(:name, body_params[:name])
          .and_return({ type: 'string' })
      end

      it 'converts parameter names to strings in schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties.keys).to all(be_a(String))
        expect(properties).to have_key('name')
      end
    end
  end

  describe 'integration with Parameters' do
    let(:method) { 'POST' }
    let(:params) { { id: {}, name: {}, email: {} } }

    let(:body_params) do
      {
        name: { type: 'String', desc: 'User name', required: true },
        email: { type: 'String', desc: 'User email', required: false }
      }
    end

    before do
      allow(parameter_schema_instance)
        .to receive(:build)
        .and_return({ type: 'string' })
    end

    it 'calls Parameters with correct arguments' do
      request_body

      expect(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters)
        .to have_received(:new)
        .with(route: route, params: params)
    end

    it 'uses body params from Parameters to build schema' do
      properties = request_body[:content]['application/json'][:schema][:properties]

      # Should only contain what Parameters returned
      expect(properties.keys).to contain_exactly('name', 'email')
    end
  end

  describe 'integration with ParameterSchema' do
    let(:method) { 'POST' }
    let(:params) { { name: {}, count: {} } }

    let(:body_params) do
      {
        name: { type: 'String', desc: 'User name', required: true },
        count: { type: 'Integer', desc: 'Count', required: false }
      }
    end

    before do
      allow(parameter_schema_instance)
        .to receive(:build)
        .with(:name, body_params[:name])
        .and_return({ type: 'string', description: 'User name' })

      allow(parameter_schema_instance)
        .to receive(:build)
        .with(:count, body_params[:count])
        .and_return({ type: 'integer', description: 'Count' })
    end

    it 'creates a single ParameterSchema instance' do
      request_body

      expect(Gitlab::GrapeOpenapi::Models::RequestBody::ParameterSchema)
        .to have_received(:new)
        .with(route: route)
        .once
    end

    it 'calls build for each body parameter' do
      request_body

      expect(parameter_schema_instance).to have_received(:build).with(:name, body_params[:name])
      expect(parameter_schema_instance).to have_received(:build).with(:count, body_params[:count])
    end

    it 'assigns returned schemas to properties' do
      properties = request_body[:content]['application/json'][:schema][:properties]

      expect(properties['name']).to eq({ type: 'string', description: 'User name' })
      expect(properties['count']).to eq({ type: 'integer', description: 'Count' })
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles

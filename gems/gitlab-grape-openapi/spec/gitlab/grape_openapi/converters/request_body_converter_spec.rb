# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Converters::RequestBodyConverter do
  let(:method) { 'POST' }
  let(:route_path) { "/api/v1/users/:id" }
  let(:params) { {} }
  let(:body_params) { {} }
  let(:options) { { method: method, params: params } }
  let(:validations) { [] }

  let(:route) do
    double('Route',
      path: route_path,
      app: double('App',
        inheritable_setting: double('InheritableSetting',
          namespace_stackable: double('NamespaceStackable',
            new_values: { validations: validations }
          )
        )
      )
    )
  end

  let(:parameters_instance) { instance_double(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters) }

  subject(:request_body) do
    described_class.convert(route: route, options: options, params: params)
  end

  before do
    allow(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters)
      .to receive(:new)
      .with(route: route, params: params)
      .and_return(parameters_instance)

    allow(parameters_instance).to receive(:extract).and_return(body_params)
  end

  describe '.convert' do
    describe 'HTTP method handling' do
      let(:params) { { name: {} } }
      let(:body_params) do
        { name: { type: 'String', desc: 'User name', required: true } }
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
      end

      %w[POST PUT PATCH].each do |http_method|
        context "with #{http_method} request" do
          let(:method) { http_method }

          it 'generates request body' do
            expect(request_body).not_to be_nil
            expect(request_body).to have_key(:content)
          end
        end
      end

      %w[HEAD OPTIONS].each do |http_method|
        context "with #{http_method} request" do
          let(:method) { http_method }

          it 'generates request body when body params exist' do
            expect(request_body).not_to be_nil
          end
        end
      end
    end

    context 'with empty params' do
      let(:method) { 'POST' }
      let(:params) { {} }

      it 'returns nil when no parameters are defined' do
        expect(request_body).to be_nil
      end

      it 'does not call Parameters when params hash is empty' do
        request_body
        expect(Gitlab::GrapeOpenapi::Models::RequestBody::Parameters).not_to have_received(:new)
      end
    end

    context 'when Parameters returns empty body params' do
      let(:method) { 'POST' }
      let(:params) { { id: { type: 'String', required: true } } }
      let(:body_params) { {} }

      it 'returns nil' do
        expect(request_body).to be_nil
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

      it 'includes descriptions in properties' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['name'][:description]).to eq('User name')
        expect(properties['email'][:description]).to eq('User email')
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

      it 'converts parameter names to strings in schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties.keys).to all(be_a(String))
        expect(properties).to have_key('name')
      end
    end
  end

  describe 'schema generation' do
    let(:method) { 'POST' }
    let(:params) { { field: {} } }

    context 'with string type' do
      let(:body_params) do
        { name: { type: 'String', desc: 'User name', required: true } }
      end

      it 'generates string schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['name'][:type]).to eq('string')
      end
    end

    context 'with integer type' do
      let(:body_params) do
        { age: { type: 'Integer', desc: 'User age', required: true } }
      end

      it 'generates integer schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['age'][:type]).to eq('integer')
      end
    end

    context 'with boolean type' do
      let(:body_params) do
        { active: { type: 'Grape::API::Boolean', desc: 'Is active', required: true } }
      end

      it 'generates boolean schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['active'][:type]).to eq('boolean')
      end
    end

    context 'with DateTime type' do
      let(:body_params) do
        { created_at: { type: 'DateTime', desc: 'Creation time', required: true } }
      end

      it 'generates string schema with date-time format' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['created_at'][:type]).to eq('string')
        expect(properties['created_at'][:format]).to eq('date-time')
      end
    end

    context 'with Hash type' do
      let(:body_params) do
        { metadata: { type: 'Hash', desc: 'Metadata object', required: true } }
      end

      it 'generates object schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['metadata'][:type]).to eq('object')
      end
    end

    context 'with default values' do
      let(:body_params) do
        {
          role: { type: 'String', desc: 'User role', required: false, default: 'member' },
          count: { type: 'Integer', desc: 'Count', required: false, default: 0 }
        }
      end

      it 'includes default values in schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['role'][:default]).to eq('member')
        expect(properties['count'][:default]).to eq(0)
      end
    end

    context 'with enum values' do
      let(:body_params) do
        {
          status: {
            type: 'String',
            desc: 'User status',
            required: true,
            values: %w[active inactive pending]
          }
        }
      end

      it 'generates enum schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['status'][:type]).to eq('string')
        expect(properties['status'][:enum]).to eq(%w[active inactive pending])
      end
    end

    context 'with range values' do
      let(:body_params) do
        {
          position: {
            type: 'Integer',
            desc: 'Position',
            required: true,
            values: (1..20)
          }
        }
      end

      it 'generates schema with minimum and maximum' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['position'][:type]).to eq('integer')
        expect(properties['position'][:minimum]).to eq(1)
        expect(properties['position'][:maximum]).to eq(20)
      end
    end

    context 'with array types (Array[String])' do
      let(:body_params) do
        { tags: { type: 'Array[String]', desc: 'User tags', required: true } }
      end

      it 'generates array schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['tags'][:type]).to eq('array')
        expect(properties['tags'][:items][:type]).to eq('arraystring')
      end
    end

    context 'with simple array type ([String])' do
      let(:body_params) do
        { milestones: { type: '[String]', desc: 'Milestone titles', required: false } }
      end

      it 'generates array schema from bracket notation type' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['milestones'][:type]).to eq('array')
        expect(properties['milestones'][:items][:type]).to eq('string')
      end
    end

    context 'with union types (oneOf)' do
      let(:body_params) do
        { value: { type: '[String, Integer]', desc: 'Value can be string or integer', required: true } }
      end

      it 'generates oneOf schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['value']).to have_key(:oneOf)
        expect(properties['value'][:oneOf]).to contain_exactly(
          { type: 'string' },
          { type: 'integer' }
        )
      end
    end

    context 'with examples' do
      let(:body_params) do
        {
          email: {
            type: 'String',
            desc: 'User email',
            required: true,
            documentation: { example: 'user@example.com' }
          }
        }
      end

      it 'includes example in schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['email'][:example]).to eq('user@example.com')
      end
    end

    context 'with parameter that has no type' do
      let(:body_params) do
        { data: { desc: 'Some data', required: true } }
      end

      it 'defaults to string type' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['data'][:type]).to eq('string')
      end
    end

    context 'with parameter that has no description' do
      let(:body_params) do
        { value: { type: 'String', required: true } }
      end

      it 'creates schema without description' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['value']).not_to have_key(:description)
      end
    end
  end

  describe 'nested structures' do
    let(:method) { 'POST' }
    let(:params) { { nested: {} } }

    context 'with nested Hash containing properties' do
      let(:body_params) do
        {
          metadata: {
            type: 'Hash',
            desc: 'Metadata object',
            required: true,
            params: {
              title: { type: 'String', desc: 'Title', required: true },
              description: { type: 'String', desc: 'Description', required: false },
              version: { type: 'Integer', desc: 'Version number', required: true }
            }
          }
        }
      end

      it 'generates object schema with nested properties' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        expect(properties['metadata'][:type]).to eq('object')
        expect(properties['metadata'][:description]).to eq('Metadata object')

        nested_props = properties['metadata'][:properties]
        expect(nested_props).to have_key('title')
        expect(nested_props).to have_key('description')
        expect(nested_props).to have_key('version')

        expect(nested_props['title'][:type]).to eq('string')
        expect(nested_props['title'][:description]).to eq('Title')

        expect(nested_props['version'][:type]).to eq('integer')
      end

      it 'includes required array for nested properties' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        expect(properties['metadata'][:required]).to contain_exactly('title', 'version')
        expect(properties['metadata'][:required]).not_to include('description')
      end
    end

    context 'with Array containing objects with properties' do
      let(:body_params) do
        {
          items: {
            type: 'Array',
            desc: 'List of items',
            required: true,
            params: {
              name: { type: 'String', desc: 'Item name', required: true },
              quantity: { type: 'Integer', desc: 'Quantity', required: true },
              notes: { type: 'String', desc: 'Optional notes', required: false }
            }
          }
        }
      end

      it 'generates array schema with object items' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        expect(properties['items'][:type]).to eq('array')
        expect(properties['items'][:description]).to eq('List of items')

        items_schema = properties['items'][:items]
        expect(items_schema[:type]).to eq('object')

        item_props = items_schema[:properties]
        expect(item_props).to have_key('name')
        expect(item_props).to have_key('quantity')
        expect(item_props).to have_key('notes')

        expect(item_props['name'][:type]).to eq('string')
        expect(item_props['quantity'][:type]).to eq('integer')
      end

      it 'includes required array for array item properties' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        items_schema = properties['items'][:items]

        expect(items_schema[:required]).to contain_exactly('name', 'quantity')
        expect(items_schema[:required]).not_to include('notes')
      end
    end

    context 'with Hash containing Array (complex nested structure)' do
      let(:body_params) do
        {
          assets: {
            type: 'Hash',
            desc: 'Object that contains assets for the release',
            required: false,
            params: {
              links: {
                type: 'Array',
                desc: 'Link information about the release',
                required: false,
                params: {
                  name: { type: 'String', desc: 'The name of the link', required: true },
                  url: { type: 'String', desc: 'The URL of the link', required: true },
                  direct_asset_path: { type: 'String', desc: 'Optional path for a direct asset link', required: false }
                }
              }
            }
          }
        }
      end

      it 'generates nested object containing array of objects' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # Top level: assets is a Hash/object
        expect(properties['assets'][:type]).to eq('object')
        expect(properties['assets'][:description]).to eq('Object that contains assets for the release')

        # Second level: links is an Array
        assets_props = properties['assets'][:properties]
        expect(assets_props['links'][:type]).to eq('array')
        expect(assets_props['links'][:description]).to eq('Link information about the release')

        # Third level: array items are objects with properties
        link_items = assets_props['links'][:items]
        expect(link_items[:type]).to eq('object')

        link_props = link_items[:properties]
        expect(link_props).to have_key('name')
        expect(link_props).to have_key('url')
        expect(link_props).to have_key('direct_asset_path')

        expect(link_props['name'][:type]).to eq('string')
        expect(link_props['url'][:type]).to eq('string')
      end

      it 'correctly handles required fields at all nesting levels' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # assets is optional, so not in top-level required
        expect(request_body[:content]['application/json'][:schema]).not_to have_key(:required)

        # links is optional within assets
        expect(properties['assets']).not_to have_key(:required)

        # name and url are required within each link object
        link_items = properties['assets'][:properties]['links'][:items]
        expect(link_items[:required]).to contain_exactly('name', 'url')
        expect(link_items[:required]).not_to include('direct_asset_path')
      end
    end

    context 'with deeply nested Hash structures' do
      let(:body_params) do
        {
          config: {
            type: 'Hash',
            desc: 'Configuration object',
            required: true,
            params: {
              database: {
                type: 'Hash',
                desc: 'Database configuration',
                required: true,
                params: {
                  host: { type: 'String', desc: 'Database host', required: true },
                  port: { type: 'Integer', desc: 'Database port', required: false, default: 5432 },
                  credentials: {
                    type: 'Hash',
                    desc: 'Database credentials',
                    required: true,
                    params: {
                      username: { type: 'String', desc: 'Username', required: true },
                      password: { type: 'String', desc: 'Password', required: true }
                    }
                  }
                }
              }
            }
          }
        }
      end

      it 'generates multi-level nested object schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # Level 1: config
        expect(properties['config'][:type]).to eq('object')

        # Level 2: database
        config_props = properties['config'][:properties]
        expect(config_props['database'][:type]).to eq('object')

        # Level 3: host, port, credentials
        db_props = config_props['database'][:properties]
        expect(db_props['host'][:type]).to eq('string')
        expect(db_props['port'][:type]).to eq('integer')
        expect(db_props['port'][:default]).to eq(5432)
        expect(db_props['credentials'][:type]).to eq('object')

        # Level 4: username, password
        cred_props = db_props['credentials'][:properties]
        expect(cred_props['username'][:type]).to eq('string')
        expect(cred_props['password'][:type]).to eq('string')
      end

      it 'correctly handles required fields at each nesting level' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # config is required at top level
        expect(request_body[:content]['application/json'][:schema][:required]).to include('config')

        # database is required within config
        expect(properties['config'][:required]).to include('database')

        # host and credentials are required, port is optional
        db_props = properties['config'][:properties]['database']
        expect(db_props[:required]).to contain_exactly('host', 'credentials')

        # username and password are required within credentials
        cred_props = db_props[:properties]['credentials']
        expect(cred_props[:required]).to contain_exactly('username', 'password')
      end
    end

    context 'with empty nested structures' do
      let(:body_params) do
        {
          metadata: {
            type: 'Hash',
            desc: 'Metadata object',
            required: false,
            params: {}
          }
        }
      end

      it 'generates object schema without properties when nested params are empty' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        expect(properties['metadata'][:type]).to eq('object')
        expect(properties['metadata'][:description]).to eq('Metadata object')
        expect(properties['metadata']).not_to have_key(:properties)
      end
    end
  end

  describe 'validations' do
    let(:method) { 'POST' }
    let(:params) { { username: {} } }
    let(:body_params) do
      { username: { type: 'String', desc: 'Username', required: true } }
    end

    let(:validations) do
      [
        {
          attributes: [:username],
          options: /^[a-z0-9_]+$/,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }
      ]
    end

    it 'includes regex pattern in schema' do
      properties = request_body[:content]['application/json'][:schema][:properties]
      expect(properties['username'][:pattern]).to eq('^[a-z0-9_]+$')
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
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles

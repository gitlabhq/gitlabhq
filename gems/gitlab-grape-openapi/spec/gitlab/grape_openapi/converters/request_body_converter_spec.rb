# frozen_string_literal: true

# rubocop:disable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Converters::RequestBodyConverter do
  let(:method) { 'POST' }
  let(:route_path) { "/api/v1/users/:id" }
  let(:route_pattern) { "/api/:version/users/:id(.:format)" }
  let(:params) { {} }
  let(:options) { { method: method, params: params } }

  let(:pattern) { double('Pattern', instance_variable_get: route_pattern) }
  let(:route) do
    double('Route',
      path: route_path,
      instance_variable_get: pattern,
      app: double('App',
        inheritable_setting: double('InheritableSetting',
          namespace_stackable: double('NamespaceStackable',
            new_values: { validations: [] }
          )
        )
      )
    )
  end

  subject(:request_body) do
    described_class.convert(route: route, options: options, params: params)
  end

  describe '.convert' do
    context 'with GET requests' do
      let(:method) { 'GET' }
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      it 'returns nil because GET requests should not have request bodies' do
        expect(request_body).to be_nil
      end
    end

    context 'with empty params' do
      let(:method) { 'POST' }
      let(:params) { {} }

      it 'returns nil when no parameters are defined' do
        expect(request_body).to be_nil
      end
    end

    context 'with only path parameters' do
      let(:method) { 'DELETE' }
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true }
        }
      end

      it 'returns nil when all parameters are in the path' do
        expect(request_body).to be_nil
      end
    end

    context 'with POST request and body parameters' do
      let(:method) { 'POST' }
      let(:params) do
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

    context 'with PUT request mixing path and body parameters' do
      let(:method) { 'PUT' }
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true },
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      it 'excludes path parameters from request body' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties).not_to have_key('id')
        expect(properties).to have_key('name')
        expect(properties).to have_key('email')
      end

      it 'only includes body parameters in required array' do
        required = request_body[:content]['application/json'][:schema][:required]
        expect(required).not_to include('id')
        expect(required).to include('name')
      end
    end

    context 'with PATCH request' do
      let(:method) { 'PATCH' }
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true },
          name: { type: 'String', desc: 'User name', required: false }
        }
      end

      it 'creates request body with optional parameters' do
        expect(request_body).not_to be_nil
        schema = request_body[:content]['application/json'][:schema]
        expect(schema[:properties]).to have_key('name')
        expect(schema[:required]).to be_nil
      end

      it 'sets required to false when no required body parameters' do
        expect(request_body[:required]).to be(false)
      end
    end

    context 'with all optional body parameters' do
      let(:method) { 'POST' }
      let(:params) do
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
  end

  describe 'schema generation' do
    let(:method) { 'POST' }

    context 'with string type' do
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true }
        }
      end

      it 'generates string schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['name'][:type]).to eq('string')
      end
    end

    context 'with integer type' do
      let(:params) do
        {
          age: { type: 'Integer', desc: 'User age', required: true }
        }
      end

      it 'generates integer schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['age'][:type]).to eq('integer')
      end
    end

    context 'with boolean type' do
      let(:params) do
        {
          active: { type: 'Grape::API::Boolean', desc: 'Is active', required: true }
        }
      end

      it 'generates boolean schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['active'][:type]).to eq('boolean')
      end
    end

    context 'with DateTime type' do
      let(:params) do
        {
          created_at: { type: 'DateTime', desc: 'Creation time', required: true }
        }
      end

      it 'generates string schema with date-time format' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['created_at'][:type]).to eq('string')
        expect(properties['created_at'][:format]).to eq('date-time')
      end
    end

    context 'with Hash type' do
      let(:params) do
        {
          metadata: { type: 'Hash', desc: 'Metadata object', required: true }
        }
      end

      it 'generates object schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['metadata'][:type]).to eq('object')
      end
    end

    context 'with default values' do
      let(:params) do
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
      let(:params) do
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

    context 'with array types' do
      let(:params) do
        {
          tags: { type: 'Array[String]', desc: 'User tags', required: true }
        }
      end

      it 'generates array schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['tags'][:type]).to eq('array')
        expect(properties['tags'][:items][:type]).to eq('arraystring')
      end
    end

    context 'with union types (oneOf)' do
      let(:params) do
        {
          value: { type: '[String, Integer]', desc: 'Value can be string or integer', required: true }
        }
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
      let(:params) do
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

    context 'with complex parameter combinations' do
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true }, # path param
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false, default: 'noreply@example.com' },
          role: { type: 'String', desc: 'User role', required: true, values: %w[admin member guest] },
          age: { type: 'Integer', desc: 'User age', required: false },
          active: { type: 'Grape::API::Boolean', desc: 'Is active', required: false, default: true }
        }
      end

      it 'generates complete schema with all parameter types' do
        schema = request_body[:content]['application/json'][:schema]
        properties = schema[:properties]

        # Path parameter excluded
        expect(properties).not_to have_key('id')

        # Required parameters
        expect(schema[:required]).to contain_exactly('name', 'role')

        # String with no special features
        expect(properties['name'][:type]).to eq('string')

        # String with default
        expect(properties['email'][:default]).to eq('noreply@example.com')

        # String with enum
        expect(properties['role'][:enum]).to eq(%w[admin member guest])

        # Integer
        expect(properties['age'][:type]).to eq('integer')

        # Boolean with default
        expect(properties['active'][:type]).to eq('boolean')
        expect(properties['active'][:default]).to be(true)
      end
    end
  end

  describe 'validations' do
    let(:method) { 'POST' }
    let(:validations) do
      [
        {
          attributes: [:username],
          options: /^[a-z0-9_]+$/,
          validator_class: Grape::Validations::Validators::RegexpValidator
        }
      ]
    end

    let(:params) do
      {
        username: { type: 'String', desc: 'Username', required: true }
      }
    end

    let(:route) do
      double('Route',
        path: route_path,
        instance_variable_get: pattern,
        app: double('App',
          inheritable_setting: double('InheritableSetting',
            namespace_stackable: double('NamespaceStackable',
              new_values: { validations: validations }
            )
          )
        )
      )
    end

    it 'includes regex pattern in schema' do
      properties = request_body[:content]['application/json'][:schema][:properties]
      expect(properties['username'][:pattern]).to eq('^[a-z0-9_]+$')
    end
  end

  describe 'edge cases' do
    let(:method) { 'POST' }

    context 'with parameter that has no type' do
      let(:params) do
        {
          data: { desc: 'Some data', required: true }
        }
      end

      it 'defaults to string type' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['data'][:type]).to eq('string')
      end
    end

    context 'with parameter that has no description' do
      let(:params) do
        {
          value: { type: 'String', required: true }
        }
      end

      it 'creates schema without description' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties['value']).not_to have_key(:description)
      end
    end

    context 'with multiple path parameters' do
      let(:route_pattern) { "/api/:version/projects/:project_id/users/:id(.:format)" }
      let(:params) do
        {
          project_id: { type: 'String', desc: 'Project ID', required: true },
          id: { type: 'String', desc: 'User ID', required: true },
          name: { type: 'String', desc: 'User name', required: true }
        }
      end

      it 'excludes all path parameters from request body' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties).not_to have_key('project_id')
        expect(properties).not_to have_key('id')
        expect(properties).to have_key('name')
      end
    end

    context 'with route that has no path parameters' do
      let(:route_pattern) { "/api/:version/users(.:format)" }
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      it 'includes all parameters in request body' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties).to have_key('name')
        expect(properties).to have_key('email')
      end
    end

    context 'with symbols as parameter keys' do
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true }
        }
      end

      it 'converts parameter names to strings in schema' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        expect(properties.keys).to all(be_a(String))
        expect(properties).to have_key('name')
      end
    end
  end

  describe 'HTTP method handling' do
    let(:params) do
      {
        name: { type: 'String', desc: 'User name', required: true }
      }
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

    %w[GET DELETE HEAD OPTIONS].each do |http_method|
      context "with #{http_method} request" do
        let(:method) { http_method }

        it 'returns nil for GET-like methods' do
          expect(request_body).to be_nil if http_method == 'GET'
        end
      end
    end
  end

  describe 'integration scenarios' do
    context 'when creating a user with full validation' do
      let(:method) { 'POST' }
      let(:route_pattern) { "/api/:version/users(.:format)" }
      let(:validations) do
        [
          {
            attributes: [:email],
            options: /^[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+$/i,
            validator_class: Grape::Validations::Validators::RegexpValidator
          }
        ]
      end

      let(:params) do
        {
          name: {
            type: 'String',
            desc: 'Full name of the user',
            required: true,
            documentation: { example: 'John Doe' }
          },
          email: {
            type: 'String',
            desc: 'Email address',
            required: true,
            documentation: { example: 'john@example.com' }
          },
          role: {
            type: 'String',
            desc: 'User role',
            required: true,
            values: %w[admin member guest],
            default: 'member'
          },
          age: {
            type: 'Integer',
            desc: 'Age in years',
            required: false
          },
          active: {
            type: 'Grape::API::Boolean',
            desc: 'Account is active',
            required: false,
            default: true
          }
        }
      end

      let(:route) do
        double('Route',
          path: "/api/v1/users",
          instance_variable_get: pattern,
          app: double('App',
            inheritable_setting: double('InheritableSetting',
              namespace_stackable: double('NamespaceStackable',
                new_values: { validations: validations }
              )
            )
          )
        )
      end

      it 'generates complete and valid request body schema' do
        expect(request_body[:required]).to be(true)

        schema = request_body[:content]['application/json'][:schema]
        expect(schema[:type]).to eq('object')
        expect(schema[:required]).to contain_exactly('name', 'email', 'role')

        properties = schema[:properties]

        # Name
        expect(properties['name']).to include(
          type: 'string',
          description: 'Full name of the user',
          example: 'John Doe'
        )

        # Email with regex validation
        expect(properties['email']).to include(
          type: 'string',
          description: 'Email address',
          example: 'john@example.com'
        )
        expect(properties['email'][:pattern]).to be_present

        # Role with enum
        expect(properties['role']).to include(
          type: 'string',
          description: 'User role',
          enum: %w[admin member guest]
        )

        # Age
        expect(properties['age']).to include(
          type: 'integer',
          description: 'Age in years'
        )

        # Active with default
        expect(properties['active']).to include(
          type: 'boolean',
          description: 'Account is active',
          default: true
        )
      end
    end

    context 'when updating a user (partial update with path param)' do
      let(:method) { 'PATCH' }
      let(:route_pattern) { "/api/:version/users/:id(.:format)" }
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true },
          name: { type: 'String', desc: 'Full name', required: false },
          email: { type: 'String', desc: 'Email address', required: false },
          active: { type: 'Grape::API::Boolean', desc: 'Account status', required: false }
        }
      end

      it 'excludes path param and makes all body params optional' do
        schema = request_body[:content]['application/json'][:schema]

        # No required params (all are optional for PATCH)
        expect(schema).not_to have_key(:required)
        expect(request_body[:required]).to be(false)

        # ID should not be in body
        properties = schema[:properties]
        expect(properties).not_to have_key('id')

        # All other params should be present
        expect(properties).to have_key('name')
        expect(properties).to have_key('email')
        expect(properties).to have_key('active')
      end
    end

    context 'with nested Hash containing properties' do
      let(:method) { 'POST' }
      let(:params) do
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
      let(:method) { 'POST' }
      let(:params) do
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
      let(:method) { 'POST' }
      let(:params) do
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
                  direct_asset_path: { type: 'String', desc: 'Optional path for a direct asset link', required: false },
                  filepath: {
                    type: 'String', desc: 'Deprecated: optional path for a direct asset link', required: false
                  },
                  link_type: { type: 'String', desc: 'The type of the link', required: false }
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
        expect(link_props).to have_key('filepath')
        expect(link_props).to have_key('link_type')

        expect(link_props['name'][:type]).to eq('string')
        expect(link_props['name'][:description]).to eq('The name of the link')

        expect(link_props['url'][:type]).to eq('string')
        expect(link_props['url'][:description]).to eq('The URL of the link')
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
        expect(link_items[:required]).not_to include('direct_asset_path', 'filepath', 'link_type')
      end
    end

    context 'with deeply nested Hash structures' do
      let(:method) { 'POST' }
      let(:params) do
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

    context 'with mixed nested structures and simple types' do
      let(:method) { 'POST' }
      let(:params) do
        {
          name: { type: 'String', desc: 'Release name', required: true },
          tag_name: { type: 'String', desc: 'Tag name', required: true },
          description: { type: 'String', desc: 'Release description', required: false },
          assets: {
            type: 'Hash',
            desc: 'Release assets',
            required: false,
            params: {
              links: {
                type: 'Array',
                desc: 'Asset links',
                required: false,
                params: {
                  name: { type: 'String', desc: 'Link name', required: true },
                  url: { type: 'String', desc: 'Link URL', required: true }
                }
              }
            }
          },
          milestones: {
            type: 'Array[String]',
            desc: 'Associated milestone titles',
            required: false
          }
        }
      end

      it 'generates schema with both nested and simple types' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # Simple types
        expect(properties['name'][:type]).to eq('string')
        expect(properties['tag_name'][:type]).to eq('string')
        expect(properties['description'][:type]).to eq('string')

        # Simple array type
        expect(properties['milestones'][:type]).to eq('array')

        # Nested complex type
        expect(properties['assets'][:type]).to eq('object')
        assets_props = properties['assets'][:properties]
        expect(assets_props['links'][:type]).to eq('array')

        link_items = assets_props['links'][:items]
        expect(link_items[:type]).to eq('object')
        expect(link_items[:properties]).to have_key('name')
        expect(link_items[:properties]).to have_key('url')
      end

      it 'correctly identifies required fields across all types' do
        schema = request_body[:content]['application/json'][:schema]

        # Only simple required fields at top level
        expect(schema[:required]).to contain_exactly('name', 'tag_name')

        # Nested required fields
        properties = schema[:properties]
        link_items = properties['assets'][:properties]['links'][:items]
        expect(link_items[:required]).to contain_exactly('name', 'url')
      end
    end

    context 'with Array containing nested objects with arrays' do
      let(:method) { 'POST' }
      let(:params) do
        {
          releases: {
            type: 'Array',
            desc: 'List of releases',
            required: true,
            params: {
              version: { type: 'String', desc: 'Version number', required: true },
              files: {
                type: 'Array',
                desc: 'Release files',
                required: false,
                params: {
                  filename: { type: 'String', desc: 'File name', required: true },
                  size: { type: 'Integer', desc: 'File size in bytes', required: true }
                }
              }
            }
          }
        }
      end

      it 'generates nested array within array items' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # Top level array
        expect(properties['releases'][:type]).to eq('array')

        # Items are objects
        release_items = properties['releases'][:items]
        expect(release_items[:type]).to eq('object')

        # Object has a simple property and a nested array
        release_props = release_items[:properties]
        expect(release_props['version'][:type]).to eq('string')
        expect(release_props['files'][:type]).to eq('array')

        # Nested array items are objects
        file_items = release_props['files'][:items]
        expect(file_items[:type]).to eq('object')
        expect(file_items[:properties]['filename'][:type]).to eq('string')
        expect(file_items[:properties]['size'][:type]).to eq('integer')
      end

      it 'handles required fields in nested array structures' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        release_items = properties['releases'][:items]
        expect(release_items[:required]).to include('version')
        expect(release_items[:required]).not_to include('files')

        file_items = release_items[:properties]['files'][:items]
        expect(file_items[:required]).to contain_exactly('filename', 'size')
      end
    end

    context 'with empty nested structures' do
      let(:method) { 'POST' }
      let(:params) do
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

    context 'with bracket notation (real Grape format)' do
      let(:method) { 'POST' }
      let(:route_pattern) { "/api/:version/projects/:id/releases(.:format)" }
      let(:params) do
        {
          "id" => { required: true, desc: "The ID or URL-encoded path of the project", type: "[String, Integer]" },
          "tag_name" => { required: true, desc: "The tag where the release is created from", type: "String" },
          "name" => { required: false, desc: "The release name", type: "String" },
          "description" => { required: false, desc: "The description of the release", type: "String" },
          "assets" => { required: false, desc: "Object that contains assets for the release", type: "Hash" },
          "assets[links]" => { required: false, desc: "Link information about the release", type: "Array" },
          "assets[links][name]" => { required: true, desc: "The name of the link", type: "String" },
          "assets[links][url]" => { required: true, desc: "The URL of the link", type: "String" },
          "assets[links][filepath]" => { required: false, desc: "Optional path", type: "String" },
          "milestones" => { required: false, desc: "Milestone titles", type: "[String]" }
        }
      end

      it 'parses bracket notation into nested structure' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # id should be excluded (path param)
        expect(properties).not_to have_key('id')

        # Top-level params
        expect(properties['tag_name'][:type]).to eq('string')
        expect(properties['name'][:type]).to eq('string')
        expect(properties['description'][:type]).to eq('string')

        # assets should be an object
        expect(properties['assets'][:type]).to eq('object')
        expect(properties['assets'][:description]).to eq('Object that contains assets for the release')
      end

      it 'creates nested array structure from bracket notation' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        assets_props = properties['assets'][:properties]

        # links should be an array within assets
        expect(assets_props['links'][:type]).to eq('array')
        expect(assets_props['links'][:description]).to eq('Link information about the release')

        # links items should be objects with properties
        link_items = assets_props['links'][:items]
        expect(link_items[:type]).to eq('object')
        expect(link_items[:properties]).to have_key('name')
        expect(link_items[:properties]).to have_key('url')
        expect(link_items[:properties]).to have_key('filepath')
      end

      it 'handles required fields in bracket notation' do
        properties = request_body[:content]['application/json'][:schema][:properties]
        link_items = properties['assets'][:properties]['links'][:items]

        # name and url are required within link items
        expect(link_items[:required]).to contain_exactly('name', 'url')
        expect(link_items[:required]).not_to include('filepath')
      end

      it 'handles simple array types with bracket notation' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # milestones should be array of strings
        expect(properties['milestones'][:type]).to eq('array')
        expect(properties['milestones'][:items][:type]).to eq('string')
        expect(properties['milestones'][:description]).to eq('Milestone titles')
      end
    end

    context 'with deeply nested bracket notation' do
      let(:method) { 'POST' }
      let(:params) do
        {
          "config" => { required: true, desc: "Configuration", type: "Hash" },
          "config[database]" => { required: true, desc: "Database config", type: "Hash" },
          "config[database][host]" => { required: true, desc: "DB host", type: "String" },
          "config[database][port]" => { required: false, desc: "DB port", type: "Integer" }
        }
      end

      it 'handles multiple levels of bracket notation' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        expect(properties['config'][:type]).to eq('object')

        config_props = properties['config'][:properties]
        expect(config_props['database'][:type]).to eq('object')

        db_props = config_props['database'][:properties]
        expect(db_props['host'][:type]).to eq('string')
        expect(db_props['port'][:type]).to eq('integer')
      end
    end

    context 'with 4+ levels of bracket notation (demonstrates depth limitation bug)' do
      let(:method) { 'POST' }
      let(:params) do
        {
          "config" => { required: true, desc: "Configuration", type: "Hash" },
          "config[database]" => { required: true, desc: "Database config", type: "Hash" },
          "config[database][pool]" => { required: true, desc: "Connection pool config", type: "Hash" },
          "config[database][pool][max_connections]" => { required: true, desc: "Maximum connections", type: "Integer" },
          "config[database][pool][min_connections]" => { required: false, desc: "Minimum connections", type: "Integer" }
        }
      end

      it 'correctly marks required fields at the 4th level' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # This will fail because pool[:properties] doesn't exist at 4th level
        pool_props = properties.dig('config', :properties, 'database', :properties, 'pool', :properties)

        expect(pool_props).not_to be_nil,
          "Expected 4th level nesting to exist but pool[:properties] is nil. " \
            "The bug causes 4+ level bracket notation to be mishandled."

        # max_connections is required, min_connections is not
        expect(pool_props['max_connections']).to be_present
        expect(pool_props['min_connections']).to be_present
      end
    end

    context 'with 5+ levels of bracket notation' do
      let(:method) { 'POST' }
      let(:params) do
        {
          "app" => { required: true, desc: "Application", type: "Hash" },
          "app[config]" => { required: true, desc: "Configuration", type: "Hash" },
          "app[config][database]" => { required: true, desc: "Database config", type: "Hash" },
          "app[config][database][pool]" => { required: true, desc: "Connection pool", type: "Hash" },
          "app[config][database][pool][settings]" => { required: true, desc: "Pool settings", type: "Hash" },
          "app[config][database][pool][settings][max_connections]" => {
            required: true, desc: "Max connections", type: "Integer"
          },
          "app[config][database][pool][settings][min_connections]" => {
            required: false, desc: "Min connections", type: "Integer"
          },
          "app[config][database][pool][settings][timeout]" => {
            required: false, desc: "Connection timeout", type: "Integer"
          }
        }
      end

      it 'handles 5 levels of bracket notation' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        # Level 1: app
        expect(properties['app'][:type]).to eq('object')

        # Level 2: app.config
        app_props = properties['app'][:properties]
        expect(app_props['config'][:type]).to eq('object')

        # Level 3: app.config.database
        config_props = app_props['config'][:properties]
        expect(config_props['database'][:type]).to eq('object')

        # Level 4: app.config.database.pool
        db_props = config_props['database'][:properties]
        expect(db_props['pool'][:type]).to eq('object')

        # Level 5: app.config.database.pool.settings
        pool_props = db_props['pool'][:properties]
        expect(pool_props['settings'][:type]).to eq('object')

        # Level 6: app.config.database.pool.settings.max_connections, etc.
        settings_props = pool_props['settings'][:properties]
        expect(settings_props).to have_key('max_connections')
        expect(settings_props['max_connections'][:type]).to eq('integer')
        expect(settings_props['max_connections'][:description]).to eq('Max connections')

        expect(settings_props).to have_key('min_connections')
        expect(settings_props['min_connections'][:type]).to eq('integer')

        expect(settings_props).to have_key('timeout')
        expect(settings_props['timeout'][:type]).to eq('integer')
      end

      it 'correctly handles required fields at 5+ levels' do
        properties = request_body[:content]['application/json'][:schema][:properties]

        settings_props = properties.dig('app', :properties, 'config', :properties,
          'database', :properties, 'pool', :properties,
          'settings', :properties)

        # Verify all 5th level properties exist
        expect(settings_props['max_connections']).to be_present
        expect(settings_props['min_connections']).to be_present
        expect(settings_props['timeout']).to be_present
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers, RSpec/VerifiedDoubles

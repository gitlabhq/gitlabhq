# frozen_string_literal: true

# rubocop:disable RSpec/VerifiedDoubles
RSpec.describe Gitlab::GrapeOpenapi::Models::RequestBody::Parameters do
  let(:route_path) { "/api/v1/users/:id" }
  let(:route_pattern) { "/api/:version/users/:id(.:format)" }
  let(:params) { {} }

  let(:pattern) { double('Pattern', instance_variable_get: route_pattern) }
  let(:route) do
    double('Route',
      path: route_path,
      instance_variable_get: pattern
    )
  end

  subject(:parameters) { described_class.new(route: route, params: params) }

  describe '#extract' do
    context 'with empty params' do
      let(:params) { {} }

      it 'returns empty hash when no parameters are defined' do
        expect(parameters.extract).to eq({})
      end
    end

    context 'with only path parameters' do
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true }
        }
      end

      it 'excludes path parameters from body' do
        result = parameters.extract
        expect(result).to be_empty
      end
    end

    context 'with body parameters only' do
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      it 'includes all body parameters' do
        result = parameters.extract
        expect(result).to have_key(:name)
        expect(result).to have_key(:email)
        expect(result[:name]).to eq({ type: 'String', desc: 'User name', required: true })
        expect(result[:email]).to eq({ type: 'String', desc: 'User email', required: false })
      end
    end

    context 'with mixing path and body parameters' do
      let(:params) do
        {
          id: { type: 'String', desc: 'User ID', required: true },
          name: { type: 'String', desc: 'User name', required: true },
          email: { type: 'String', desc: 'User email', required: false }
        }
      end

      it 'excludes path parameters from body' do
        result = parameters.extract
        expect(result).not_to have_key(:id)
        expect(result).to have_key(:name)
        expect(result).to have_key(:email)
      end

      it 'preserves all parameter options for body parameters' do
        result = parameters.extract
        expect(result[:name]).to eq({ type: 'String', desc: 'User name', required: true })
        expect(result[:email]).to eq({ type: 'String', desc: 'User email', required: false })
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

      it 'excludes all path parameters from body' do
        result = parameters.extract
        expect(result).not_to have_key(:project_id)
        expect(result).not_to have_key(:id)
        expect(result).to have_key(:name)
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

      it 'includes all parameters in body' do
        result = parameters.extract
        expect(result).to have_key(:name)
        expect(result).to have_key(:email)
      end
    end

    context 'with symbols as parameter keys' do
      let(:params) do
        {
          name: { type: 'String', desc: 'User name', required: true }
        }
      end

      it 'preserves parameter keys as provided' do
        result = parameters.extract
        expect(result).to have_key(:name)
      end
    end

    context 'with string parameter keys' do
      let(:params) do
        {
          "name" => { type: 'String', desc: 'User name', required: true }
        }
      end

      it 'preserves parameter keys as provided' do
        result = parameters.extract
        expect(result).to have_key("name")
      end
    end

    context 'with pre-nested params structure (not bracket notation)' do
      let(:params) do
        {
          metadata: {
            type: 'Hash',
            desc: 'Metadata object',
            required: true,
            params: {
              title: { type: 'String', desc: 'Title', required: true },
              version: { type: 'Integer', desc: 'Version number', required: false }
            }
          }
        }
      end

      it 'preserves pre-nested params structure unchanged' do
        result = parameters.extract

        expect(result).to have_key(:metadata)
        expect(result[:metadata][:type]).to eq('Hash')
        expect(result[:metadata][:desc]).to eq('Metadata object')
        expect(result[:metadata][:required]).to be(true)

        nested_params = result[:metadata][:params]
        expect(nested_params).to have_key(:title)
        expect(nested_params[:title][:type]).to eq('String')
        expect(nested_params[:title][:required]).to be(true)

        expect(nested_params).to have_key(:version)
        expect(nested_params[:version][:type]).to eq('Integer')
        expect(nested_params[:version][:required]).to be(false)
      end
    end

    context 'with pre-nested Array params structure' do
      let(:params) do
        {
          items: {
            type: 'Array',
            desc: 'List of items',
            required: true,
            params: {
              name: { type: 'String', desc: 'Item name', required: true },
              quantity: { type: 'Integer', desc: 'Quantity', required: true }
            }
          }
        }
      end

      it 'preserves pre-nested Array params structure unchanged' do
        result = parameters.extract

        expect(result).to have_key(:items)
        expect(result[:items][:type]).to eq('Array')
        expect(result[:items][:params]).to have_key(:name)
        expect(result[:items][:params]).to have_key(:quantity)
      end
    end

    context 'with deeply pre-nested params structure' do
      let(:params) do
        {
          config: {
            type: 'Hash',
            desc: 'Configuration',
            required: true,
            params: {
              database: {
                type: 'Hash',
                desc: 'Database config',
                required: true,
                params: {
                  host: { type: 'String', desc: 'Host', required: true },
                  credentials: {
                    type: 'Hash',
                    desc: 'Credentials',
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

      it 'preserves deeply nested structure unchanged' do
        result = parameters.extract

        credentials = result.dig(:config, :params, :database, :params, :credentials, :params)
        expect(credentials).to have_key(:username)
        expect(credentials).to have_key(:password)
        expect(credentials[:username][:type]).to eq('String')
      end
    end

    context 'with bracket notation (real Grape format)' do
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
        result = parameters.extract

        # id should be excluded (path param)
        expect(result).not_to have_key('id')

        # Top-level params
        expect(result).to have_key('tag_name')
        expect(result).to have_key('name')
        expect(result).to have_key('description')

        # assets should be an object
        expect(result).to have_key('assets')
        expect(result['assets'][:type]).to eq('Hash')
        expect(result['assets'][:desc]).to eq('Object that contains assets for the release')
      end

      it 'creates nested array structure from bracket notation' do
        result = parameters.extract
        assets = result['assets']

        # links should be nested within assets
        expect(assets[:params]).to have_key('links')
        expect(assets[:params]['links'][:type]).to eq('Array')
        expect(assets[:params]['links'][:desc]).to eq('Link information about the release')

        # links should have nested properties
        links = assets[:params]['links']
        expect(links[:params]).to have_key('name')
        expect(links[:params]).to have_key('url')
        expect(links[:params]).to have_key('filepath')
      end

      it 'preserves required flags in bracket notation' do
        result = parameters.extract
        link_params = result['assets'][:params]['links'][:params]

        # name and url are required
        expect(link_params['name'][:required]).to be(true)
        expect(link_params['url'][:required]).to be(true)

        # filepath is optional
        expect(link_params['filepath'][:required]).to be(false)
      end

      it 'preserves descriptions in bracket notation' do
        result = parameters.extract
        link_params = result['assets'][:params]['links'][:params]

        expect(link_params['name'][:desc]).to eq('The name of the link')
        expect(link_params['url'][:desc]).to eq('The URL of the link')
        expect(link_params['filepath'][:desc]).to eq('Optional path')
      end

      it 'preserves types in bracket notation' do
        result = parameters.extract
        link_params = result['assets'][:params]['links'][:params]

        expect(link_params['name'][:type]).to eq('String')
        expect(link_params['url'][:type]).to eq('String')
        expect(link_params['filepath'][:type]).to eq('String')
      end

      it 'handles simple types alongside bracket notation' do
        result = parameters.extract

        # milestones should remain as-is (not bracket notation)
        expect(result).to have_key('milestones')
        expect(result['milestones'][:type]).to eq('[String]')
        expect(result['milestones'][:desc]).to eq('Milestone titles')
      end
    end

    context 'with deeply nested bracket notation' do
      let(:params) do
        {
          "config" => { required: true, desc: "Configuration", type: "Hash" },
          "config[database]" => { required: true, desc: "Database config", type: "Hash" },
          "config[database][host]" => { required: true, desc: "DB host", type: "String" },
          "config[database][port]" => { required: false, desc: "DB port", type: "Integer" }
        }
      end

      it 'handles multiple levels of bracket notation' do
        result = parameters.extract

        expect(result).to have_key('config')
        expect(result['config'][:type]).to eq('Hash')

        config_params = result['config'][:params]
        expect(config_params).to have_key('database')
        expect(config_params['database'][:type]).to eq('Hash')

        db_params = config_params['database'][:params]
        expect(db_params).to have_key('host')
        expect(db_params['host'][:type]).to eq('String')
        expect(db_params).to have_key('port')
        expect(db_params['port'][:type]).to eq('Integer')
      end

      it 'preserves all parameter options at each level' do
        result = parameters.extract

        # Level 1
        expect(result['config'][:required]).to be(true)
        expect(result['config'][:desc]).to eq('Configuration')

        # Level 2
        config_params = result['config'][:params]
        expect(config_params['database'][:required]).to be(true)
        expect(config_params['database'][:desc]).to eq('Database config')

        # Level 3
        db_params = config_params['database'][:params]
        expect(db_params['host'][:required]).to be(true)
        expect(db_params['host'][:desc]).to eq('DB host')
        expect(db_params['port'][:required]).to be(false)
        expect(db_params['port'][:desc]).to eq('DB port')
      end
    end

    context 'with 4+ levels of bracket notation' do
      let(:params) do
        {
          "config" => { required: true, desc: "Configuration", type: "Hash" },
          "config[database]" => { required: true, desc: "Database config", type: "Hash" },
          "config[database][pool]" => { required: true, desc: "Connection pool config", type: "Hash" },
          "config[database][pool][max_connections]" => { required: true, desc: "Maximum connections", type: "Integer" },
          "config[database][pool][min_connections]" => { required: false, desc: "Minimum connections", type: "Integer" }
        }
      end

      it 'correctly handles 4th level nesting' do
        result = parameters.extract

        # Navigate to 4th level
        pool_params = result.dig('config', :params, 'database', :params, 'pool', :params)

        expect(pool_params).not_to be_nil,
          "Expected 4th level nesting to exist but pool[:params] is nil"

        # max_connections is required, min_connections is not
        expect(pool_params).to have_key('max_connections')
        expect(pool_params['max_connections'][:required]).to be(true)
        expect(pool_params['max_connections'][:desc]).to eq('Maximum connections')
        expect(pool_params['max_connections'][:type]).to eq('Integer')

        expect(pool_params).to have_key('min_connections')
        expect(pool_params['min_connections'][:required]).to be(false)
        expect(pool_params['min_connections'][:desc]).to eq('Minimum connections')
        expect(pool_params['min_connections'][:type]).to eq('Integer')
      end
    end

    context 'with 5+ levels of bracket notation' do
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
        result = parameters.extract

        # Level 1: app
        expect(result).to have_key('app')
        expect(result['app'][:type]).to eq('Hash')

        # Level 2: app.config
        app_params = result['app'][:params]
        expect(app_params).to have_key('config')
        expect(app_params['config'][:type]).to eq('Hash')

        # Level 3: app.config.database
        config_params = app_params['config'][:params]
        expect(config_params).to have_key('database')
        expect(config_params['database'][:type]).to eq('Hash')

        # Level 4: app.config.database.pool
        db_params = config_params['database'][:params]
        expect(db_params).to have_key('pool')
        expect(db_params['pool'][:type]).to eq('Hash')

        # Level 5: app.config.database.pool.settings
        pool_params = db_params['pool'][:params]
        expect(pool_params).to have_key('settings')
        expect(pool_params['settings'][:type]).to eq('Hash')

        # Level 6: app.config.database.pool.settings.max_connections, etc.
        settings_params = pool_params['settings'][:params]
        expect(settings_params).to have_key('max_connections')
        expect(settings_params['max_connections'][:type]).to eq('Integer')
        expect(settings_params['max_connections'][:desc]).to eq('Max connections')

        expect(settings_params).to have_key('min_connections')
        expect(settings_params['min_connections'][:type]).to eq('Integer')

        expect(settings_params).to have_key('timeout')
        expect(settings_params['timeout'][:type]).to eq('Integer')
      end

      it 'correctly handles required fields at 5+ levels' do
        result = parameters.extract

        settings_params = result.dig('app', :params, 'config', :params,
          'database', :params, 'pool', :params,
          'settings', :params)

        # Verify all 5th level properties exist with correct required flags
        expect(settings_params['max_connections'][:required]).to be(true)
        expect(settings_params['min_connections'][:required]).to be(false)
        expect(settings_params['timeout'][:required]).to be(false)
      end
    end

    context 'with mixed nested structures and simple types' do
      let(:params) do
        {
          name: { type: 'String', desc: 'Release name', required: true },
          tag_name: { type: 'String', desc: 'Tag name', required: true },
          description: { type: 'String', desc: 'Release description', required: false },
          "assets" => { type: 'Hash', desc: 'Release assets', required: false },
          "assets[links]" => { type: 'Array', desc: 'Asset links', required: false },
          "assets[links][name]" => { type: 'String', desc: 'Link name', required: true },
          "assets[links][url]" => { type: 'String', desc: 'Link URL', required: true },
          milestones: { type: 'Array[String]', desc: 'Associated milestone titles', required: false }
        }
      end

      it 'handles both nested and simple types' do
        result = parameters.extract

        # Simple types
        expect(result).to have_key(:name)
        expect(result[:name][:type]).to eq('String')
        expect(result).to have_key(:tag_name)
        expect(result[:tag_name][:type]).to eq('String')
        expect(result).to have_key(:description)
        expect(result[:description][:type]).to eq('String')

        # Simple array type
        expect(result).to have_key(:milestones)
        expect(result[:milestones][:type]).to eq('Array[String]')

        # Nested complex type
        expect(result).to have_key('assets')
        expect(result['assets'][:type]).to eq('Hash')
        assets_params = result['assets'][:params]
        expect(assets_params).to have_key('links')
        expect(assets_params['links'][:type]).to eq('Array')

        link_params = assets_params['links'][:params]
        expect(link_params).to have_key('name')
        expect(link_params).to have_key('url')
      end
    end

    context 'with empty nested structures' do
      let(:params) do
        {
          "metadata" => { type: 'Hash', desc: 'Metadata object', required: false }
        }
      end

      it 'creates structure without nested params when none provided' do
        result = parameters.extract

        expect(result).to have_key('metadata')
        expect(result['metadata'][:type]).to eq('Hash')
        expect(result['metadata'][:desc]).to eq('Metadata object')
        expect(result['metadata']).not_to have_key(:params)
      end
    end

    context 'with bracket notation merging with root param' do
      let(:params) do
        {
          "assets" => { required: false, desc: "Assets object", type: "Hash" },
          "assets[links]" => { required: false, desc: "Links array", type: "Array" }
        }
      end

      it 'merges bracket notation params with root param' do
        result = parameters.extract

        expect(result).to have_key('assets')
        expect(result['assets'][:type]).to eq('Hash')
        expect(result['assets'][:desc]).to eq('Assets object')
        expect(result['assets'][:required]).to be(false)

        # Nested params should be added
        expect(result['assets'][:params]).to have_key('links')
        expect(result['assets'][:params]['links'][:type]).to eq('Array')
      end
    end

    context 'with complex parameter combinations including path params' do
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

      it 'excludes path parameter and includes all body parameters with their options' do
        result = parameters.extract

        # Path parameter excluded
        expect(result).not_to have_key(:id)

        # All body parameters included
        expect(result).to have_key(:name)
        expect(result).to have_key(:email)
        expect(result).to have_key(:role)
        expect(result).to have_key(:age)
        expect(result).to have_key(:active)

        # Verify all options are preserved
        expect(result[:name]).to eq({ type: 'String', desc: 'User name', required: true })
        expect(result[:email]).to eq(
          { type: 'String', desc: 'User email', required: false, default: 'noreply@example.com' }
        )
        expect(result[:role]).to eq(
          { type: 'String', desc: 'User role', required: true, values: %w[admin member guest] }
        )
        expect(result[:age]).to eq({ type: 'Integer', desc: 'User age', required: false })
        expect(result[:active]).to eq(
          { type: 'Grape::API::Boolean', desc: 'Is active', required: false, default: true }
        )
      end
    end

    context 'with parameters containing various options' do
      let(:params) do
        {
          username: { type: 'String', desc: 'Username', required: true },
          email: { type: 'String', desc: 'Email', required: true, documentation: { example: 'user@example.com' } },
          status: { type: 'String', desc: 'Status', required: true, values: %w[active inactive] },
          age: { type: 'Integer', desc: 'Age', required: false, values: (18..100) },
          role: { type: 'String', desc: 'Role', required: false, default: 'member' }
        }
      end

      it 'preserves all parameter options including examples, enums, ranges, and defaults' do
        result = parameters.extract

        expect(result[:username]).to eq({ type: 'String', desc: 'Username', required: true })
        expect(result[:email]).to eq(
          { type: 'String', desc: 'Email', required: true, documentation: { example: 'user@example.com' } }
        )
        expect(result[:status]).to eq({ type: 'String', desc: 'Status', required: true, values: %w[active inactive] })
        expect(result[:age]).to eq({ type: 'Integer', desc: 'Age', required: false, values: (18..100) })
        expect(result[:role]).to eq({ type: 'String', desc: 'Role', required: false, default: 'member' })
      end
    end

    context 'with bracket notation at different depths in same structure' do
      let(:params) do
        {
          "config" => { required: true, desc: "Config", type: "Hash" },
          "config[name]" => { required: true, desc: "Config name", type: "String" },
          "config[database]" => { required: true, desc: "Database", type: "Hash" },
          "config[database][host]" => { required: true, desc: "Host", type: "String" },
          "config[database][port]" => { required: false, desc: "Port", type: "Integer" }
        }
      end

      it 'correctly handles mixed depth bracket notation' do
        result = parameters.extract

        expect(result['config'][:params]).to have_key('name')
        expect(result['config'][:params]['name'][:type]).to eq('String')

        expect(result['config'][:params]).to have_key('database')
        expect(result['config'][:params]['database'][:type]).to eq('Hash')

        db_params = result['config'][:params]['database'][:params]
        expect(db_params).to have_key('host')
        expect(db_params).to have_key('port')
      end
    end

    context 'with only bracket notation params (no root param defined)' do
      let(:params) do
        {
          "assets[links][name]" => { required: true, desc: "Link name", type: "String" },
          "assets[links][url]" => { required: true, desc: "Link URL", type: "String" }
        }
      end

      it 'creates the full nested structure from bracket notation alone' do
        result = parameters.extract

        expect(result).to have_key('assets')
        expect(result['assets'][:type]).to eq('Hash')
        expect(result['assets'][:required]).to be(false)

        expect(result['assets'][:params]).to have_key('links')
        expect(result['assets'][:params]['links'][:type]).to eq('Hash')

        links_params = result['assets'][:params]['links'][:params]
        expect(links_params).to have_key('name')
        expect(links_params).to have_key('url')
      end
    end

    context 'with special characters in parameter values' do
      let(:params) do
        {
          pattern: { type: 'String', desc: 'Regex pattern like ^[a-z]+$', required: true },
          url: {
            type: 'String',
            desc: 'URL with special chars',
            required: false,
            default: 'https://example.com?foo=bar&baz=qux'
          }
        }
      end

      it 'preserves special characters in descriptions and defaults' do
        result = parameters.extract

        expect(result[:pattern][:desc]).to eq('Regex pattern like ^[a-z]+$')
        expect(result[:url][:default]).to eq('https://example.com?foo=bar&baz=qux')
      end
    end

    context 'with nil values in parameter options' do
      let(:params) do
        {
          field: { type: 'String', desc: nil, required: true, default: nil }
        }
      end

      it 'preserves nil values in parameter options' do
        result = parameters.extract

        expect(result[:field][:desc]).to be_nil
        expect(result[:field][:default]).to be_nil
        expect(result[:field][:required]).to be(true)
      end
    end

    context 'with empty string values in parameter options' do
      let(:params) do
        {
          field: { type: 'String', desc: '', required: true }
        }
      end

      it 'preserves empty string values' do
        result = parameters.extract

        expect(result[:field][:desc]).to eq('')
      end
    end
  end
end
# rubocop:enable RSpec/VerifiedDoubles

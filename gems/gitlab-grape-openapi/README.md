# GitLab Grape OpenAPI

> [!WARNING]
> This gem is currently designed entirely for internal use at GitLab. This gem is not functional and not used in production.

Internal gem for generating [OpenAPI 3.0](https://spec.openapis.org/oas/v3.0.0) specifications from [Grape](https://github.com/ruby-grape/grape) API definitions.

## Installation

Add to your Gemfile:

```ruby
gem 'gitlab-grape-openapi', path: 'gems/gitlab-grape-openapi'
```

## Configuration

Configure the gem using the `Gitlab::GrapeOpenapi.configure` block, typically in an initializer:

```ruby
Gitlab::GrapeOpenapi.configure do |config|
  # Required: API metadata
  config.info = Gitlab::GrapeOpenapi::Models::Info.new(
    title: 'My API',
    description: 'API description',
    version: 'v1',
    terms_of_service: 'https://example.com/terms'
  )

  # API path configuration
  config.api_prefix = "api"    # Default: "api"
  config.api_version = "v1"    # Default: "v1"

  # Server definitions
  config.servers = [
    Gitlab::GrapeOpenapi::Models::Server.new(
      url: 'https://{hostname}/',
      description: "Production API",
      variables: {
        hostname: Gitlab::GrapeOpenapi::Models::ServerVariable.new(
          default: 'api.example.com',
          description: 'API hostname'
        )
      }
    )
  ]

  # Security schemes
  config.security_schemes = [
    Gitlab::GrapeOpenapi::Models::SecurityScheme.new(
      name: "bearerAuth",
      type: "http",
      scheme: "bearer"
    )
  ]

  # Exclude specific API classes from generation
  config.excluded_api_classes = [
    'API::Internal::Base',
    'API::Internal::Admin'
  ]

  # Override tag names for better display
  config.tag_overrides = {
    'Ci' => 'CI',
    'Oauth' => 'OAuth'
  }

  # Map Grape route settings to OpenAPI extensions
  config.annotations = {
    lifecycle: 'x-gitlab-lifecycle'
  }
end
```

### Configuration Options

| Option                 | Type                            | Default | Description                                                  |
| ---------------------- | ------------------------------- | ------- | ------------------------------------------------------------ |
| `info`                 | `Models::Info`                  | `nil`   | API metadata (title, description, version, terms of service) |
| `api_prefix`           | `String`                        | `"api"` | URL prefix for API routes                                    |
| `api_version`          | `String`                        | `"v1"`  | API version string                                           |
| `servers`              | `Array<Models::Server>`         | `[]`    | Server definitions for the API                               |
| `security_schemes`     | `Array<Models::SecurityScheme>` | `[]`    | Authentication/authorization schemes                         |
| `excluded_api_classes` | `Array<String>`                 | `[]`    | API class names to exclude from generation                   |
| `tag_overrides`        | `Hash`                          | `{}`    | Map of tag names to their display overrides                  |
| `annotations`          | `Hash`                          | `{}`    | Map of Grape route settings to OpenAPI extension names       |

### Annotations

The `annotations` configuration maps Grape route settings to OpenAPI vendor extensions. For example:

```ruby
config.annotations = {
  lifecycle: 'x-gitlab-lifecycle'
}

When a Grape endpoint has:

```ruby
route_setting :lifecycle, 'mature'
```

The generated OpenAPI spec will include:

```yaml
x-gitlab-lifecycle: mature
```

## Usage

### Generating an OpenAPI Specification

```ruby
# Load all API and entity classes
Rails.application.eager_load!

api_classes = API::Base.descendants
entity_classes = Grape::Entity.descendants

# Generate the specification
spec = Gitlab::GrapeOpenapi.generate(
  api_classes: api_classes,
  entity_classes: entity_classes
)

# Output as JSON
File.write('openapi.json', JSON.pretty_generate(spec))

# Or as YAML
require 'yaml'
File.write('openapi.yaml', spec.to_yaml)
```

### Usage with `gitlab-org/gitlab`

1. Start a Rails console in your GDK:

   ```bash
   cd ~/gdk/gitlab
   rails console
   ```

2. Generate the OpenAPI specification:

   ```ruby
   Rails.application.eager_load!
   api_classes = API::Base.descendants
   entity_classes = Grape::Entity.descendants
   spec = Gitlab::GrapeOpenapi.generate(api_classes: api_classes, entity_classes: entity_classes)
   File.write(Rails.root.join('tmp', 'openapi.json'), JSON.pretty_generate(spec))
   ```

3. The spec will be saved to `tmp/openapi.json` in your GitLab directory.

## Architecture

The gem follows a converter-based architecture:

```
Generator
├── TagConverter        - Extracts tags from API classes
├── EntityConverter     - Converts Grape::Entity to OpenAPI schemas
├── PathConverter       - Converts routes to OpenAPI paths
│   ├── OperationConverter  - Converts individual endpoints
│   ├── ParameterConverter  - Converts endpoint parameters
│   ├── ResponseConverter   - Converts endpoint responses
│   └── RequestBodyConverter - Converts request bodies
└── TypeResolver        - Maps Ruby/Grape types to OpenAPI types
```

### Registries

- **SchemaRegistry** - Tracks converted entity schemas
- **RequestBodyRegistry** - Tracks request body schemas
- **TagRegistry** - Tracks API tags

## Development

```bash
cd gems/gitlab-grape-openapi
bundle install
bundle exec rspec
```

### Running Tests

```bash
bundle exec rspec
```

### Linting

```bash
bundle exec rubocop
```

## Contributing

This gem is part of the GitLab monorepo. Please follow the [GitLab contribution guidelines](https://docs.gitlab.com/ee/development/contributing/).

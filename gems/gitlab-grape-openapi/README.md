# GitLab Grape OpenAPI

> [!warning]
> This gem is currently designed entirely for internal use at GitLab. This gem is not functional and not used in production.

Internal gem for generating OpenAPI 3.0 specifications from Grape API definitions.

## Usage

```ruby
require "gitlab/grape_openapi"

Gitlab::GrapeOpenapi.configure do |config|
  config.api_version = "v4"
  # omitted for brevity
end

specification = Gitlab::GrapeOpenapi.generate([ExampleAPI])
```

## Development

```bash
bundle install
bundle exec rspec
```

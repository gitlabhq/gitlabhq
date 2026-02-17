# ActionDispatch::DrawAll

A Rails routing extension that adds a `draw_all` method to `ActionDispatch::Routing::Mapper`. This allows you to load multiple route files matching a pattern from your `config/routes` directories.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'action_dispatch-draw_all'
```

And then execute:

```bash
bundle install
```

## Usage

In your `config/routes.rb`, you can use `draw_all` to load all matching route files:

```ruby
Rails.application.routes.draw do
  draw_all :api
  draw_all :admin
  draw_all :public
end
```

This will load:
- `config/routes/api.rb`
- `config/routes/admin.rb`
- `config/routes/public.rb`

### Multiple Routes Directories

If you have multiple routes directories configured in your Rails application, `draw_all` will load matching files from all of them:

```ruby
# config/application.rb
config.paths['config/routes'].concat([
  Rails.root.join('config/routes'),
  Rails.root.join('config/routes_ee')
])
```

Then in `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  draw_all :api  # Loads both config/routes/api.rb and config/routes_ee/api.rb
end
```

## Error Handling

If a route file matching the pattern is not found in any of the configured routes directories, a `ActionDispatch::DrawAll::RoutesNotFound` exception is raised with a helpful error message:

```ruby
Rails.application.routes.draw do
  draw_all :nonexistent  # Raises ActionDispatch::DrawAll::RoutesNotFound
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## License

MIT

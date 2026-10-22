# gitlab-banzai

Banzai is the GitLab Flavored Markdown rendering pipeline: a chain of
`HTML::Pipeline` filters that turn user-supplied markdown into the HTML
GitLab serves. This gem holds the part of `lib/banzai/` that has been lifted
out of the monolith.

The gem is a product feature, not platform infrastructure. It is not part of
the `gitlab-platform-*` family and never depends on a
`gitlab-platform-<area>` gem. It may depend on `gitlab-platform-core` once
that gem lands.

## What belongs here

A file is a candidate only if it has no ActiveRecord surface at all:

- No model reference, no `ActiveRecord`, no policy or `Ability` check.
- No Rails routing: no `Gitlab::Routing`, no `url_helpers`, no `*_url` or
  `*_path` helper.
- No `Feature.enabled?`, `Gitlab::CurrentSettings`, `Gitlab.config` or
  `Settings.`.
- No EE surface: no `prepend_mod`, and no `ee/lib/ee/banzai/<same path>`
  counterpart.

Anything a filter needs from GitLab comes in through a port instead; see
"Configuration" below.

## Naming and paths

Constants keep their original names and paths. Moving a file into this gem
never changes a call site. `Banzai::Filter::HtmlEntityFilter` stays
`Banzai::Filter::HtmlEntityFilter` and lives at
`gems/gitlab-banzai/lib/banzai/filter/html_entity_filter.rb`.

`Banzai.render` and the rest of the `Banzai` facade moved here with
`lib/banzai.rb`. They delegate to `Banzai::Renderer`, which the monolith
still owns and Zeitwerk resolves at call time. `lib/banzai.rb` could not stay
behind: once this gem defines the `Banzai` constant at boot, Zeitwerk treats
the monolith's `lib/banzai.rb` as a shadowed file and never loads it.

The rest of `lib/banzai/` stays in the monolith and is still autoloaded. A
directory whose namespace constant already exists is one Zeitwerk descends
into rather than defines, the same way `lib/gitlab/utils/` is autoloaded
under the `Gitlab::Utils` that `gitlab-utils` defines.

## Configuration

Anything the gem cannot derive on its own is an input on
`Banzai::Configuration`, wired by the monolith in
`config/initializers/0_banzai.rb`:

```ruby
Banzai.configure do |config|
  config.url_builder = ->(object) { Gitlab::UrlBuilder.build(object) }
end
```

An input accepts a plain value or a callable. Callables are resolved on every
read, not at boot, so a spec that stubs the underlying monolith state still
changes what the gem sees. Reading an input that was never set raises
`Banzai::MissingConfigurationError`, which names the input and how to set it.

A reader passes its arguments through to the callable. The `url_builder` port
above is declared on `Banzai::Configuration` as a reader that takes the
object, and the gem calls it as `Banzai.configuration.url_builder(object)`:

```ruby
attr_writer :url_builder

def url_builder(object)
  resolve(:url_builder, @url_builder, object)
end
```

An input without arguments, such as a flag, is configured as a plain value or
as a callable with no arguments.

The inputs declared so far:

| Input | Shape | GitLab adapter |
| --- | --- | --- |
| `timeout_disabled` | flag | `Gitlab::RenderTimeout.banzai_timeout_disabled?` |
| `with_timeout` | `(seconds) { ... }`, raises `Timeout::Error` | `Gitlab::RenderTimeout.timeout` |
| `track_exception` | `(exception, **extra)` | `Gitlab::ErrorTracking.track_exception` |

The gem's own specs drive the inputs with in-memory fakes, set in
`spec/spec_helper.rb`.

## How it is loaded

The entry point is `lib/banzai/all.rb`. It requires every file the gem owns.
The monolith loads it from `config/application.rb`:

```ruby
require 'banzai/all'
```

This sits next to the existing `require 'gitlab/utils/all'`. Both requires
run before Zeitwerk initializes, so the constants are real modules by the
time autoloading starts.

## Adding a file

1. Move the source file with `git mv` from `lib/banzai/` to
   `gems/gitlab-banzai/lib/banzai/`.
2. Move its spec with `git mv` from `spec/lib/banzai/` to
   `gems/gitlab-banzai/spec/banzai/`. A spec that drives the monolith's full
   pipeline stays behind as integration coverage; write the gem a unit spec
   that feeds the filter HTML directly.
3. Add a `require_relative` line for the new file to `lib/banzai/all.rb`.
4. Remove any stale entries for the old paths from `.rubocop_todo/` and from
   `spec/support/rspec_order_todo.yml`.

## Development

Run these from the gem directory:

```shell
bundle install
bundle exec rspec
bundle exec rubocop
```

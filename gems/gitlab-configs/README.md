# gitlab-configs

`gitlab-configs` provides GitLab's YAML-based settings loading with lazy evaluation
and safe options access, extracted from the GitLab monolith.

## How gitlab.yml is parsed

GitLab stores its application configuration in `gitlab.yml` (documented at
https://docs.gitlab.com/omnibus/settings/gitlab.yml). When the application
boots, the gem reads the file, selects the section matching the current
environment, and exposes the resulting config tree with method-style key
access. Loading is lazy: the file is not read until the first attribute
access or an explicit `#reload!` call.

## Public interface

### `Gitlab::Configs.load`

Loads a YAML config file and returns the section's config tree:

```ruby
require 'gitlab/configs'

Settings = Gitlab::Configs.load('/path/to/gitlab.yml', Rails.env)
Settings.smtp.address  # => 'localhost'
```

### `Gitlab::Configs.build_options`

Builds a config object from an arbitrary hash without loading a file.
Useful in initializers and tests:

```ruby
opts = Gitlab::Configs.build_options({ smtp: { address: 'localhost' } })
opts.smtp.address  # => 'localhost'
```

### `Gitlab::Configs.on_mutation_warning=`

Controls what happens when a caller invokes a mutating Hash method on a
config object. Default: raise. The monolith overrides this in production
to log instead of raising:

```ruby
Gitlab::Configs.on_mutation_warning = ->(message, extra) do
  raise message unless Rails.env.production?

  # `caller` and `method` are captured inside the gem (at the real mutation
  # call site) and passed through in `extra` — use them rather than
  # re-capturing `caller` here, which would log this dispatch layer instead.
  payload = { message: message, caller: extra[:caller], method: extra[:method] }
  Gitlab::AppJsonLogger.warn(payload)
end
```

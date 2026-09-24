# gitlab-mfe

Configuration and vendor pins for GitLab micro-frontend (MFE) delivery.

The gem reads a `vendor/mfe.yml` file passed in during the configuration and
exposes GitLab vendored micro-frontends. It carries no `ActiveRecord`, `Rails`,
`Feature`, or `Gitlab.config` dependency: the host application injects those
runtime hooks through `Gitlab::Mfe.configure`.

## Usage

```ruby
require "gitlab/mfe"

# Wired once by the host application (e.g. a Rails initializer):
Gitlab::Mfe.configure do |config|
  config.enabled = -> { Gitlab.config.mfe.enabled && Feature.enabled?(:mfe_enabled, :instance) }
  config.registry_url = -> { Gitlab.config.mfe.registry_url }
  config.vendor_file_path = -> { Rails.root.join('vendor/mfe.yml') }
end

Gitlab::Mfe.enabled?      # => whatever the injected enabled hook resolves to
Gitlab::Mfe.registry_url  # => configured registry, or DEFAULT_REGISTRY_URL

Gitlab::Mfe::VendorFile.entries # => frozen [Entry(name:, version:, sha:), ...]
```

Each hook accepts a callable or a plain value. `enabled` and `registry_url`
fall back to safe defaults (delivery off, default registry) so the gem and its
specs run without a host application; `vendor_file_path` has no default and must
be supplied by the host.

# Environment selection

Some tests are designed to be run against specific environments. We can specify
what environments to run tests against using the `only` metadata.

## Available switches

| Switch | Function | Type |
| -------| ------- | ----- |
| `tld`  | Set the top-level domain matcher | `String` |
| `subdomain` | Set the subdomain matcher | `Array` or `String` |
| `domain` | Set the domain matcher | `String` |
| `production` | Match against production | `Static` |

CAUTION: **Caution:**
You cannot specify `:production` and `{ <switch>: 'value' }` simultaneously.  
These options are mutually exclusive. If you want to specify production, you
can control the `tld` and `domain` independently.

## Examples

| Environment                              | Key | Matches (regex)                                                            |
| ----------------                         | --- | ---------------                                                            |
| `any`                                    | ``  | `.+.com`                                                                   |
| `gitlab.com`                             | `only: :production` | `gitlab.com`                                               |
| `staging.gitlab.com`                     | `only: { subdomain: :staging }` | `(staging).+.com`                              |
| `gitlab.com and staging.gitlab.com`      | `only: { subdomain: /(staging.)?/, domain: 'gitlab' }` | `(staging.)?gitlab.com` |
| `dev.gitlab.org`                         | `only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org` |
| `staging.gitlab.com & domain.gitlab.com` | `only: { subdomain: %i[staging domain] }` | `(staging|domain).+.com`             |

```ruby
RSpec.describe 'Area' do
  it 'runs in any environment' do; end

  it 'runs only in production', only: :production do; end

  it 'runs only in staging', only: { subdomain: :staging } do; end

  it 'runs in dev', only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' } do; end

  it 'runs in prod and staging', only: { subdomain: /(staging.)?/, domain: 'gitlab' } {}
end
```

NOTE: **Note:**
If the test has a `before` or `after`, you must add the `only` metadata
to the outer `RSpec.describe`.

## Quarantining a test for a specific environment

Similarly to specifying that a test should only run against a specific environment, it's also possible to quarantine a
test only when it runs against a specific environment. The syntax is exactly the same, except that the `only: { ... }`
hash is nested in the [`quarantine: { ... }`](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests) hash.
For instance, `quarantine: { only: { subdomain: :staging } }` will only quarantine the test when run against staging.

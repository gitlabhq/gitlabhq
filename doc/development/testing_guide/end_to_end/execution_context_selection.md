---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Execution context selection

Some tests are designed to be run against specific environments, or in specific [pipelines](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#scheduled-qa-test-pipelines) or jobs. We can specify the test execution context using the `only` and `except` metadata.

## Available switches

| Switch | Function | Type |
| -------| ------- | ----- |
| `tld`  | Set the top-level domain matcher | `String` |
| `subdomain` | Set the subdomain matcher | `Array` or `String` |
| `domain` | Set the domain matcher | `String` |
| `production` | Match the production environment | `Static` |
| `pipeline` | Match a pipeline | `Array` or `Static`|
| `job` | Match a job | `Array` or `Static`|

WARNING:
You cannot specify `:production` and `{ <switch>: 'value' }` simultaneously.
These options are mutually exclusive. If you want to specify production, you
can control the `tld` and `domain` independently.

## Examples

### Only

Run tests in only the specified context.

Matches use:

- Regex for environments.
- String matching for pipelines.
- Regex or string matching for jobs.

| Test execution context                   | Key | Matches |
| ----------------                         | --- | ---------------                                                            |
| `gitlab.com`                             | `only: :production` | `gitlab.com`                                               |
| `staging.gitlab.com`                     | `only: { subdomain: :staging }` | `(staging).+.com`                              |
| `gitlab.com and staging.gitlab.com`      | `only: { subdomain: /(staging.)?/, domain: 'gitlab' }` | `(staging.)?gitlab.com` |
| `dev.gitlab.org`                         | `only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org` |
| `staging.gitlab.com and domain.gitlab.com` | `only: { subdomain: %i[staging domain] }` | `(staging\|domain).+.com`             |
| The `nightly` pipeline                     | `only: { pipeline: :nightly }` | "nightly" |
| The `nightly` and `canary` pipelines | `only: { pipeline: [:nightly, :canary] }` | ["nightly"](https://gitlab.com/gitlab-org/quality/nightly) and ["canary"](https://gitlab.com/gitlab-org/quality/canary) |
| The `ee:instance` job | `only: { job: 'ee:instance' }` | The `ee:instance` job in any pipeline |
| Any `quarantine` job | `only: { job: '.*quarantine' }` | Any job ending in `quarantine` in any pipeline |

```ruby
RSpec.describe 'Area' do
  it 'runs in any environment or pipeline' do; end
  it 'runs only in production environment', only: :production do; end

  it 'runs only in staging environment', only: { subdomain: :staging } do; end

  it 'runs in dev environment', only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' } do; end

  it 'runs in prod and staging environments', only: { subdomain: /(staging.)?/, domain: 'gitlab' } {}

  it 'runs only in nightly pipeline', only: { pipeline: :nightly } do; end

  it 'runs in nightly and canary pipelines', only: { pipeline: [:nightly, :canary] } do; end
end
```

### Except

Run tests in their typical contexts _except_ as specified.

Matches use:

- Regex for environments.
- String matching for pipelines.
- Regex or string matching for jobs.

| Test execution context                   | Key | Matches |
| ----------------                         | --- | ---------------                                                            |
| `gitlab.com`                             | `except: :production` | `gitlab.com`                                               |
| `staging.gitlab.com`                     | `except: { subdomain: :staging }` | `(staging).+.com`                              |
| `gitlab.com and staging.gitlab.com`      | `except: { subdomain: /(staging.)?/, domain: 'gitlab' }` | `(staging.)?gitlab.com` |
| `dev.gitlab.org`                         | `except: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org` |
| `staging.gitlab.com and domain.gitlab.com` | `except: { subdomain: %i[staging domain] }` | `(staging\|domain).+.com`             |
| The `nightly` pipeline                     | `except: { pipeline: :nightly }` | ["nightly"](https://gitlab.com/gitlab-org/quality/nightly) |
| The `nightly` and `canary` pipelines | `except: { pipeline: [:nightly, :canary] }` | ["nightly"](https://gitlab.com/gitlab-org/quality/nightly) and ["canary"](https://gitlab.com/gitlab-org/quality/canary) |
| The `ee:instance` job | `except: { job: 'ee:instance' }` | The `ee:instance` job in any pipeline |
| Any `quarantine` job | `except: { job: '.*quarantine' }` | Any job ending in `quarantine` in any pipeline |

```ruby
RSpec.describe 'Area' do
  it 'runs in any execution context except the production environment', except: :production do; end

  it 'runs in any execution context except the staging environment', except: { subdomain: :staging } do; end

  it 'runs in any execution context except the nightly pipeline', except: { pipeline: :nightly } do; end

  it 'runs in any execution context except the ee:instance job', except: { job: 'ee:instance' } do; end
end
```

## Usage notes

If the test has a `before` or `after` block, you must add the `only` or `except` metadata to the outer `RSpec.describe` block.

To run a test tagged with `only` on your local GitLab instance, you can do one of the following:

- Make sure you **do not** have the `CI_PROJECT_NAME` or `CI_JOB_NAME` environment variables set.
- Set the appropriate variable to match the metadata. For example, if the metadata is `only: { pipeline: :nightly }` then set `CI_PROJECT_NAME=nightly`. If the metadata is `only: { job: 'ee:instance' }` then set `CI_JOB_NAME=ee:instance`.
- Temporarily remove the metadata.

To run a test tagged with `except` locally, you can either:

- Make sure you **do not** have the `CI_PROJECT_NAME` or `CI_JOB_NAME` environment variables set.
- Temporarily remove the metadata.

## Quarantine a test for a specific environment

Similarly to specifying that a test should only run against a specific environment, it's also possible to quarantine a
test only when it runs against a specific environment. The syntax is exactly the same, except that the `only: { ... }`
hash is nested in the [`quarantine: { ... }`](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#quarantining-tests) hash.
For example, `quarantine: { only: { subdomain: :staging } }` only quarantines the test when run against `staging`.

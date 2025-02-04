---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Execution context selection
---

Some tests are designed to be run against specific environments, or in specific [pipelines](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/debugging-qa-test-failures/#qa-test-pipelines) or jobs. We can specify the test execution context using the `only` and `except` metadata.

## Available switches

| Switch       | Function                         | Type                |
| ------------ | -------------------------------- | ------------------- |
| `tld`        | Set the top-level domain matcher | `String`            |
| `subdomain`  | Set the subdomain matcher        | `Array` or `String` |
| `domain`     | Set the domain matcher           | `String`            |
| `production` | Match the production environment | `Static`            |
| `pipeline`   | Match a pipeline                 | `Array` or `Static` |
| `job`        | Match a job                      | `Array` or `Static` |

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
- Regex or string matching for jobs
- Lambda or truthy/falsey value for generic condition

| Test execution context                              | Key                                                         | Matches                                                                                                                                                |
| --------------------------------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gitlab.com`                                        | `only: :production`                                         | `gitlab.com`                                                                                                                                           |
| `staging.gitlab.com`                                | `only: { subdomain: :staging }`                             | `(staging).+.com`                                                                                                                                      |
| `gitlab.com and staging.gitlab.com`                 | `only: { subdomain: /(staging.)?/, domain: 'gitlab' }`      | `(staging.)?gitlab.com`                                                                                                                                |
| `dev.gitlab.org`                                    | `only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org`                                                                                                                                     |
| `staging.gitlab.com and domain.gitlab.com`          | `only: { subdomain: %i[staging domain] }`                   | `(staging\|domain).+.com`                                                                                                                              |
| The `nightly` pipeline                              | `only: { pipeline: :nightly }`                              | ["nightly scheduled pipeline"](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules)                                                              |
| The `nightly` and `canary` pipelines                | `only: { pipeline: [:nightly, :canary] }`                   | ["nightly scheduled pipeline"](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules) and ["canary"](https://gitlab.com/gitlab-org/quality/canary) |
| The `ee:instance` job                               | `only: { job: 'ee:instance' }`                              | The `ee:instance` job in any pipeline                                                                                                                  |
| Any `quarantine` job                                | `only: { job: '.*quarantine' }`                             | Any job ending in `quarantine` in any pipeline                                                                                                         |
| Local development environment                       | `only: :local`                                              | Any environment where `Runtime::Env.running_in_ci?` is false                                                                                           |
| Any run where condition evaluates to a truthy value | `only: { condition: -> { ENV['TEST_ENV'] == 'true' } }`     | Any run where `TEST_ENV` is set to true                                                                                                                |

```ruby
RSpec.describe 'Area' do
  it 'runs in any environment or pipeline' do; end
  it 'runs only in production environment', only: :production do; end

  it 'runs only in staging environment', only: { subdomain: :staging } do; end

  it 'runs in dev environment', only: { tld: '.org', domain: 'gitlab', subdomain: 'dev' } do; end

  it 'runs in prod and staging environments', only: { subdomain: /(staging.)?/, domain: 'gitlab' } {}

  it 'runs only in nightly pipeline', only: { pipeline: :nightly } do; end

  it 'runs in nightly and canary pipelines', only: { pipeline: [:nightly, :canary] } do; end

  it 'runs in specific environment matching condition', only: { condition: -> { ENV['TEST_ENV'] == 'true' } } do; end
end
```

### Except

Run tests in their typical contexts _except_ as specified.

Matches use:

- Regex for environments.
- String matching for pipelines.
- Regex or string matching for jobs
- Lambda or truthy/falsey value for generic condition

| Test execution context                                     | Key                                                           | Matches                                                                                                                                                |
| ---------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gitlab.com`                                               | `except: :production`                                         | `gitlab.com`                                                                                                                                           |
| `staging.gitlab.com`                                       | `except: { subdomain: :staging }`                             | `(staging).+.com`                                                                                                                                      |
| `gitlab.com and staging.gitlab.com`                        | `except: { subdomain: /(staging.)?/, domain: 'gitlab' }`      | `(staging.)?gitlab.com`                                                                                                                                |
| `dev.gitlab.org`                                           | `except: { tld: '.org', domain: 'gitlab', subdomain: 'dev' }` | `(dev).gitlab.org`                                                                                                                                     |
| `staging.gitlab.com and domain.gitlab.com`                 | `except: { subdomain: %i[staging domain] }`                   | `(staging\|domain).+.com`                                                                                                                              |
| The `nightly` pipeline                                     | `only: { pipeline: :nightly }`                                | ["nightly scheduled pipeline"](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules)                                                              |
| The `nightly` and `canary` pipelines                       | `only: { pipeline: [:nightly, :canary] }`                     | ["nightly scheduled pipeline"](https://gitlab.com/gitlab-org/gitlab/-/pipeline_schedules) and ["canary"](https://gitlab.com/gitlab-org/quality/canary) |
| The `ee:instance` job                                      | `except: { job: 'ee:instance' }`                              | The `ee:instance` job in any pipeline                                                                                                                  |
| Any `quarantine` job                                       | `except: { job: '.*quarantine' }`                             | Any job ending in `quarantine` in any pipeline                                                                                                         |
| Any run except where condition evaluates to a truthy value | `except: { condition: -> { ENV['TEST_ENV'] == 'true' } }`     | Any run where `TEST_ENV` is not set to true                                                                                                            |

```ruby
RSpec.describe 'Area' do
  it 'runs in any execution context except the production environment', except: :production do; end

  it 'runs in any execution context except the staging environment', except: { subdomain: :staging } do; end

  it 'runs in any execution context except the nightly pipeline', except: { pipeline: :nightly } do; end

  it 'runs in any execution context except the ee:instance job', except: { job: 'ee:instance' } do; end

  it 'runs in specific environment not matching condition', except: { condition: -> { ENV['TEST_ENV'] == 'true' } } do; end
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
hash is nested in the [`quarantine: { ... }`](https://handbook.gitlab.com/handbook/engineering/infrastructure/test-platform/debugging-qa-test-failures/#quarantining-tests) hash.
For example, `quarantine: { only: { subdomain: :staging } }` only quarantines the test when run against `staging`.

The quarantine feature can be explicitly disabled with the `DISABLE_QUARANTINE` environment variable. This can be useful when running tests locally.

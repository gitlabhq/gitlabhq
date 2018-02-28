# GitLab Developers Guide to Working with Gitaly

[Gitaly](https://gitlab.com/gitlab-org/gitaly) is a high-level Git RPC service used by GitLab CE/EE,
Workhorse and GitLab-Shell. All Rugged operations in GitLab CE/EE are currently being phased out to
be replaced by Gitaly API calls.

Visit the [Gitaly Migration Board](https://gitlab.com/gitlab-org/gitaly/boards/331341) for current
status of the migration.

## Feature Flags

Gitaly makes heavy use of [feature flags](feature_flags.md).

Each Rugged-to-Gitaly migration goes through a [series of phases](https://gitlab.com/gitlab-org/gitaly/blob/master/doc/MIGRATION_PROCESS.md):

* **Opt-In**: by default the Rugged implementation is used.
  * Production instances can choose to enable the Gitaly endpoint by enabling the feature flag.
  * For testing purposes, you may wish to enable all feature flags by default. This can be done by exporting the following
    environment variable: `GITALY_FEATURE_DEFAULT_ON=1`.
  * On developer instances (ie, when `Rails.env.development?` is true), the Gitaly endpoint
    is enabled by default, but can be _disabled_ using feature flags.
* **Opt-Out**: by default, the Gitaly endpoint is used, but the feature can be explicitly disabled using the feature flag.
* **Mandatory**: The migration is complete and cannot be disabled. The old codepath is removed.

### Enabling and Disabling Feature

In the Rails console, type:

```ruby
Feature.enable(:gitaly_feature_name)
Feature.disable(:gitaly_feature_name)
```

Where `gitaly_feature_name` is the name of the Gitaly feature. This can be determined by finding the appropriate
`gitaly_migrate` code block, for example:

```ruby
gitaly_migrate(:tag_names) do
...
end
```

Since Gitaly features are always prefixed with `gitaly_`, the name of the feature flag in this case would be `gitaly_tag_names`.

## Gitaly-Related Test Failures

If your test-suite is failing with Gitaly issues, as a first step, try running:

```shell
rm -rf tmp/tests/gitaly
```

## `TooManyInvocationsError` errors

During development and testing, you may experience `Gitlab::GitalyClient::TooManyInvocationsError` failures.
The `GitalyClient` will attempt to block against potential n+1 issues by raising this error
when Gitaly is called more than 30 times in a single Rails request or Sidekiq execution.

As a temporary measure, export `GITALY_DISABLE_REQUEST_LIMITS=1` to suppress the error. This will disable the n+1 detection
in your development environment.

Please raise an issue in the GitLab CE or EE repositories to report the issue. Include the labels ~Gitaly
~performance ~"technical debt". Please ensure that the issue contains the full stack trace and error message of the
`TooManyInvocationsError`. Also include any known failing tests if possible.

Isolate the source of the n+1 problem. This will normally be a loop that results in Gitaly being called for each
element in an array. If you are unable to isolate the problem, please contact a member
of the [Gitaly Team](https://gitlab.com/groups/gl-gitaly/group_members) for assistance.

Once the source has been found, wrap it in an `allow_n_plus_1_calls` block, as follows:

```ruby
# n+1: link to n+1 issue
Gitlab::GitalyClient.allow_n_plus_1_calls do
  # original code
  commits.each { |commit| ... }
end
```

Once the code is wrapped in this block, this code-path will be excluded from n+1 detection.

## Request counts

Commits and other git data, is now fetched through Gitaly. These fetches can,
much like with a database, be batched. This improves performance for the client
and for Gitaly itself and therefore for the users too. To keep performance stable
and guard performance regressions, Gitaly calls can be counted and the call count
can be tested against. This requires the `:request_store` flag to be set.

```ruby
describe 'Gitaly Request count tests' do
  context 'when the request store is activated', :request_store do
    it 'correctly counts the gitaly requests made' do
      expect { subject }.to change { Gitlab::GitalyClient.get_request_count }.by(10)
    end
  end
end
```

## Running tests with a locally modified version of Gitaly

Normally, gitlab-ce/ee tests use a local clone of Gitaly in `tmp/tests/gitaly`
pinned at the version specified in GITALY_SERVER_VERSION. If you want
to run tests locally against a modified version of Gitaly you can
replace `tmp/tests/gitaly` with a symlink.

```shell
rm -rf tmp/tests/gitaly
ln -s /path/to/gitaly tmp/tests/gitaly
```

Make sure you run `make` in your local Gitaly directory before running
tests. Otherwise, Gitaly will fail to boot.

If you make changes to your local Gitaly in between test runs you need
to manually run `make` again.

Note that CI tests will not use your locally modified version of
Gitaly. To use a custom Gitaly version in CI you need to update
GITALY_SERVER_VERSION. You can use the format `=revision` to use a
non-tagged commit from https://gitlab.com/gitlab-org/gitaly in CI.

---

[Return to Development documentation](README.md)

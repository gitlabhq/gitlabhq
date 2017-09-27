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
* **Madatory**: The migration is complete and cannot be disabled. The old codepath is removed.

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

---

[Return to Development documentation](README.md)

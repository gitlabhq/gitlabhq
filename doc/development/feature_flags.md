# Manage feature flags

Starting from GitLab 9.3 we support feature flags for features in GitLab via
[Flipper](https://github.com/jnunemaker/flipper/). You should use the `Feature`
class (defined in `lib/feature.rb`) in your code to get, set and list feature
flags.

During runtime you can set the values for the gates via the
[features API](../api/features.md) (accessible to admins only).

## Feature groups

Starting from GitLab 9.4 we support feature groups via
[Flipper groups](https://github.com/jnunemaker/flipper/blob/v0.10.2/docs/Gates.md#2-group).

Feature groups must be defined statically in `lib/feature.rb` (in the
`.register_feature_groups` method), but their implementation can obviously be
dynamic (querying the DB etc.).

Once defined in `lib/feature.rb`, you will be able to activate a
feature for a given feature group via the [`feature_group` param of the features API](../api/features.md#set-or-create-a-feature)

## Feature flags for user applications

GitLab does not yet support the use of feature flags in deployed user applications.
You can follow the progress on that [in the issue on our issue tracker](https://gitlab.com/gitlab-org/gitlab-ee/issues/779).
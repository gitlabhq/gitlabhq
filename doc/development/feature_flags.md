# Manage feature flags

Starting from GitLab 9.3 we support feature flags via
[Flipper](https://github.com/jnunemaker/flipper/). You should use the `Feature`
class (defined in `lib/feature.rb`) in your code to get, set and list feature
flags. During runtime you can set the values for the gates via the
[admin API](../api/features.md).

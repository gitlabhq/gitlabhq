<!-- Title suggestion: [Feature flag] Remove FEATURE_FLAG_NAME -->

## Feature

The `:feature_name` feature flag was previously [enabled by default](URL) and should be removed.

## Owners

- Group: ~"group::GROUP_NAME"
- Slack channel: `#g_GROUP_NAME`
- DRI: USERNAME
- PM: USERNAME

**Removal**

This is an __important__ phase, that should be either done in the next Milestone or as soon as possible. For the cleanup phase, please follow our documentation on how to  [clean up the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up).

- [ ] Remove `:feature_name` feature flag
    - [ ] Remove all references to the feature flag from the codebase
    - [ ] Remove the YAML definitions for the feature from the repository
    - [ ] Create a Changelog Entry

- [ ] Clean up the feature flag from all environments by running this chatops command in `#production` channel `/chatops run feature delete some_feature`.

- [ ] Close this issue after the feature flag is removed from the codebase.

/label ~"feature flag" ~"technical debt"
/assign DRI

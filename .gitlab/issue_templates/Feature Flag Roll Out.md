<!-- Title suggestion: [Feature flag] Enable description of feature -->

## Summary

This issue is to rollout [the feature](ISSUE LINK) on production,
that is currently behind the `<feature-flag-name>` feature flag.

<!-- Short description of what the feature is about and link to relevant other issues. -->

## Owners

- Team: NAME_OF_TEAM
- Most appropriate slack channel to reach out to: `#g_TEAM_NAME`
- Best individual to reach out to: NAME
- PM: NAME

## Stakeholders

<!--
Are there any other stages or teams involved that need to be kept in the loop?

- Name of a PM
- The Support Team
- The Delivery Team
-->

## The Rollout Plan

- Partial Rollout on GitLab.com with testing groups
- Rollout on GitLab.com for a certain period (How long)
- Percentage Rollout on GitLab.com
- Rollout Feature for everyone as soon as it's ready

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant? Sentry errors reports can also be useful to review -->

## Testing Groups/Projects/Users

<!-- If applicable, any groups/projects that are happy to have this feature turned on early. Some organizations may wish to test big changes they are interested in with a small subset of users ahead of time for example. -->

- `gitlab-org/gitlab` project
- `gitlab-org`/`gitlab-com` groups
- ...


## Expectations

### What are we expecting to happen?

<!-- Describe the expected outcome when rolling out this feature -->

### What might happen if this goes wrong?

<!-- Should the feature flag be turned off? Any MRs that need to be rolled back? Communication that needs to happen? What are some things you can think of that could go wrong - data loss or broken pages? -->

### What can we monitor to detect problems with this?

<!-- Which dashboards from https://dashboards.gitlab.net are most relevant? -->

## Rollout Steps

### Rollout on non-production environments

- [ ] Ensure that the feature MRs have been deployed to non-production environments.
    - [ ] `/chatops run auto_deploy status <merge-commit-of-your-feature>`
- [ ] Enable the feature globally on non-production environments.
    - [ ] `/chatops run feature set <feature-flag-name> true --dev`
    - [ ] `/chatops run feature set <feature-flag-name> true --staging`
- [ ] Verify that the feature works as expected. Posting the QA result in this issue is preferable.

### Preparation before production rollout

- [ ] Ensure that the feature MRs have been deployed to both production and canary.
    - [ ] `/chatops run auto_deploy status <merge-commit-of-your-feature>`
- [ ] Check if the feature flag change needs to be accompanied with a
  [change management issue](https://about.gitlab.com/handbook/engineering/infrastructure/change-management/#feature-flags-and-the-change-management-process).
  Cross link the issue here if it does.
- [ ] Ensure that you or a representative in development can be available for at least 2 hours after feature flag updates in production.
  If a different developer will be covering, or an exception is needed, please inform the oncall SRE by using the `@sre-oncall` Slack alias.
- [ ] Ensure that documentation has been updated ([More info](https://docs.gitlab.com/ee/development/documentation/feature_flags.html#features-that-became-enabled-by-default)).
- [ ] Announce on [the feature issue](ISSUE LINK) an estimated time this will be enabled on GitLab.com.
- [ ] If the feature might impact the user experience, notify `#support_gitlab-com` and your team channel ([more guidance when this is necessary in the dev docs](https://docs.gitlab.com/ee/development/feature_flags/controls.html#communicate-the-change)).
- [ ] If the feature flag in code has [an actor](https://docs.gitlab.com/ee/development/feature_flags/#feature-actors), enable it on GitLab.com for [testing groups/projects](#testing-groupsprojectsusers).
    - [ ] `/chatops run feature set --<actor-type>=<actor> <feature-flag-name> true`
- [ ] Verify that the feature works as expected. Posting the QA result in this issue is preferable.

### Global rollout on production

- [ ] [Incrementally roll out](https://docs.gitlab.com/ee/development/feature_flags/controls.html#process) the feature.
  - If the feature flag in code has [an actor](https://docs.gitlab.com/ee/development/feature_flags/#feature-actors), perform **actor-based** rollout.
    - [ ] `/chatops run feature set <feature-flag-name> <rollout-percentage> --actors`
  - If the feature flag in code does **NOT** have [an actor](https://docs.gitlab.com/ee/development/feature_flags/#feature-actors), perform time-based rollout (**random** rollout).
    - [ ] `/chatops run feature set <feature-flag-name> <rollout-percentage>`
  - Enable the feature globally on production environment.
    - [ ] `/chatops run feature set <feature-flag-name> true`
- [ ] Announce on [the feature issue](ISSUE LINK) that the feature has been globally enabled.
- [ ] Wait for [at least one day for the verification term](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#including-a-feature-behind-feature-flag-in-the-final-release).

### (Optional) Release the feature with the feature flag

If you're still unsure whether the feature is [deemed stable](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#including-a-feature-behind-feature-flag-in-the-final-release)
but want to release it in the current milestone, you can change the default state of the feature flag to be enabled.
To do so, follow these steps:

- [ ] Create a merge request with the following changes. Ask for review and merge it.
    - [ ] Set the `default_enabled` attribute in [the feature flag definition](https://docs.gitlab.com/ee/development/feature_flags/#feature-flag-definition-and-validation) to `true`.
    - [ ] Create [a changelog entry](https://docs.gitlab.com/ee/development/feature_flags/#changelog).
- [ ] Ensure that the default-enabling MR has been deployed to both production and canary.
      If the merge request was deployed before [the code cutoff](https://about.gitlab.com/handbook/engineering/releases/#self-managed-releases-1),
      the feature can be officially announced in a release blog post.
    - [ ] `/chatops run auto_deploy status <merge-commit-of-default-enabling-mr>`
- [ ] Close [the feature issue](ISSUE LINK) to indicate the feature will be released in the current milestone.
- [ ] Set the next milestone to this rollout issue for scheduling [the flag removal](#release-the-feature).
- [ ] (Optional) You can create a separate issue for scheduling the steps below to [Release the feature](#release-the-feature).
    - [ ] Set the title to "[Feature flag] Cleanup `<feature-flag-name>`".
    - [ ] Execute the `/copy_metadata <this-rollout-issue-link>` quick action to copy the labels from this rollout issue.
    - [ ] Link this rollout issue as a related issue.
    - [ ] Close this rollout issue.

**WARNING:** This approach has the downside that it makes it difficult for us to
[clean up](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) the flag.
For example, on-premise users could disable the feature on their GitLab instance. But when you
remove the flag at some point, they suddenly see the feature as enabled and they can't roll it back
to the previous behavior. To avoid this potential breaking change, use this approach only for urgent
matters.

### Release the feature

After the feature has been [deemed stable](https://about.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#including-a-feature-behind-feature-flag-in-the-final-release),
the [clean up](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up)
should be done as soon as possible to permanently enable the feature and reduce complexity in the
codebase.

<!-- The checklist here is to help stakeholders keep track of the feature flag status -->
- [ ] Create a merge request to remove `<feature-flag-name>` feature flag. Ask for review and merge it.
    - [ ] Remove all references to the feature flag from the codebase.
    - [ ] Remove the YAML definitions for the feature from the repository.
    - [ ] Create [a changelog entry](https://docs.gitlab.com/ee/development/feature_flags/#changelog).
- [ ] Ensure that the cleanup MR has been deployed to both production and canary.
      If the merge request was deployed before [the code cutoff](https://about.gitlab.com/handbook/engineering/releases/#self-managed-releases-1),
      the feature can be officially announced in a release blog post.
    - [ ] `/chatops run auto_deploy status <merge-commit-of-cleanup-mr>`
- [ ] Close [the feature issue](ISSUE LINK) to indicate the feature will be released in the current milestone.
- [ ] Clean up the feature flag from all environments by running these chatops command in `#production` channel:
    - [ ] `/chatops run feature delete <feature-flag-name> --dev`
    - [ ] `/chatops run feature delete <feature-flag-name> --staging`
    - [ ] `/chatops run feature delete <feature-flag-name>`
- [ ] Close this rollout issue.

## Rollback Steps

- [ ] This feature can be disabled by running the following Chatops command:

```
/chatops run feature set <feature-flag-name> false
```

/label ~"feature flag"
/assign DRI

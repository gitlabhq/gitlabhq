<!-- Title suggestion: [FF] `<feature-flag-name>` -- <short description> -->

## Summary

Roll out [the feature](<feature-issue-link>) currently behind the `<feature-flag-name>` feature flag.

- DRI: @<gitlab-username-of-dri>
- Team Slack channel: `#<slack-channel-of-dri-team>`

> [!note]
> Process and guidance live in the docs — this issue is just the commands and a place to track the rollout.
> "Rolling out" means incrementally enabling the flag on GitLab.com to validate stability — it is not the same as releasing the feature, which happens when the flag is removed.
> [Feature flag controls](https://docs.gitlab.com/development/feature_flags/controls/) · [Feature flag lifecycle](https://handbook.gitlab.com/handbook/product-development/how-we-work/product-development-flow/feature-flag-lifecycle/#feature-flag-lifecycle)

## What could go wrong?

<!-- Optional but recommended: blast radius, data-loss risk, and the dashboard(s) you'll watch on https://dashboards.gitlab.net. Delete if not applicable. -->

## Events

<!-- Replace feature flag name in the link-->
- [Exceptions with <feature-flag-name>:1](https://log.gprd.gitlab.net/app/discover#/?_g=(time:(from:now-1d,to:now))&_a=(index:'7092c4e2-4eb5-46f2-8305-a7da2edad090',query:(language:kuery,query:'json.exception.feature_flag_states.keyword:%22<feature-flag-name>:1%22'),columns:!(json.exception.class,json.exception.message,json.extra.workflow_id,json.meta.caller_id),sort:!(!(json.time,desc))))
- [Events with <feature-flag-name>:1](https://log.gprd.gitlab.net/app/discover#/?_g=(time:(from:now-1d,to:now))&_a=(index:'7092c4e2-4eb5-46f2-8305-a7da2edad090',query:(language:kuery,query:'json.feature_flag_states:%22<feature-flag-name>:1%22'),columns:!(json.meta.caller_id,json.feature_flag_states),sort:!(!(json.time,desc))))
- [Error rate and other graphs by modifying the examples in the Visualization Library](https://log.gprd.gitlab.net/app/visualize#/?_g=h@358d019&s=FF%20Observability)

Feature Flag events are only logged by default for feature flags marked for the current or future milestones. To enable while the feature flag is active, see https://docs.gitlab.com/development/feature_flags/#logging

## Rollout

Run all production `/chatops` in [`#production`](https://gitlab.slack.com/archives/C101F3796) and cross-post the results to `#<slack-channel-of-dri-team>`. Background: [incremental rollout process](https://docs.gitlab.com/development/feature_flags/controls/#process), [feature actors](https://docs.gitlab.com/development/feature_flags/#feature-actors).

**Non-production**

```
/chatops gitlab run feature set <feature-flag-name> 50 --actors --dev --pre --staging --staging-ref
/chatops gitlab run feature set <feature-flag-name> true --dev --pre --staging --staging-ref
```

**Production** — percentage rollout (wait ≥15 min between steps, watch dashboards):

```
/chatops gitlab run feature set <feature-flag-name> <percentage> --actors
```

Or target specific actors instead:

```
/chatops gitlab run feature set --project=gitlab-org/gitlab,gitlab-org/gitlab-foss <feature-flag-name> true
/chatops gitlab run feature set --group=gitlab-org,gitlab-com <feature-flag-name> true
/chatops gitlab run feature set --user=<gitlab-username-of-dri> <feature-flag-name> true
```

## Before global rollout

Confirm the relevant gotchas before going to 100% — see [enabling a feature for GitLab.com](https://docs.gitlab.com/development/feature_flags/controls/#enabling-a-feature-for-gitlabcom):

- [Docs + version history](https://docs.gitlab.com/development/documentation/feature_flags/) updated
- [Breaking changes](https://docs.gitlab.com/development/documentation/release_notes/#deprecations-removals-and-breaking-changes) announced, if any
- [Change management issue](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/change-management/#feature-flags-and-the-change-management-process) opened, if required
- [External API consumers](https://docs.gitlab.com/development/feature_flags/#do-not-use-feature-flags-in-external-api-consumers) handled with a fail-open mechanism, if applicable

## Cleanup

Remove the flag once [deemed stable](https://handbook.gitlab.com/handbook/product-development/how-we-work/product-development-flow/feature-flag-lifecycle/#feature-flag-lifecycle) — see [cleaning up](https://docs.gitlab.com/development/feature_flags/controls/#cleaning-up). Track it here, or open a follow-up [Feature Flag Cleanup issue](https://gitlab.com/gitlab-org/gitlab/-/work_items/new?description_template=Feature%20Flag%20Cleanup). Remove the flag and its YAML definition from the codebase, then:

```
/chatops gitlab run release check <merge-request-url> <milestone>
/chatops gitlab run feature delete <feature-flag-name> --dev --pre --staging --staging-ref --production
```

## Rollback

```
/chatops gitlab run feature set <feature-flag-name> false                                         # production
/chatops gitlab run feature set <feature-flag-name> false --dev --pre --staging --staging-ref     # non-production
/chatops gitlab run feature delete <feature-flag-name> --dev --pre --staging --staging-ref --production  # remove entirely
```

/label <group-label>
/label ~"feature flag"
/relate <feature-issue-link>
<!-- Uncomment the appropriate type label
/label ~"type::feature" ~"feature::addition"
/label ~"type::maintenance"
/label ~"type::bug"
-->
/assign @<gitlab-username-of-dri>
/due in 2 weeks

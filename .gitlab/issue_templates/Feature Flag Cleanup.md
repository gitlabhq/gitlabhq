<!-- Title suggestion: [Feature flag] Cleanup <feature-flag-name> -->

## Summary

This issue is to cleanup the `<feature-flag-name>` feature flag, after the feature flag has been enabled by default for an appropriate amount of time in production.

<!-- Short description of what the feature is about and link to relevant other issues. Ensure to note if the feature will be removed completely or will be productized-->

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

## Expectations

### What might happen if this goes wrong?

<!-- Any MRs that need to be rolled back? Communication that needs to happen? What are some things you can think of that could go wrong - data loss or broken pages? -->

### Cleaning up the feature flag

<!-- The checklist here is to help stakeholders keep track of the feature flag status -->
- [ ] Specify in the issue description if this feature will be removed completely or will be productized as part of the Feature Flag cleanup 
- [ ] Create a merge request to remove `<feature-flag-name>` feature flag. Ask for review and merge it.
    - [ ] Remove all references to the feature flag from the codebase.
    - [ ] Remove the YAML definitions for the feature from the repository.
    - [ ] Create [a changelog entry](https://docs.gitlab.com/ee/development/feature_flags/#changelog).
- [ ] Ensure that the cleanup MR has been deployed to both production and canary.
      If the merge request was deployed before [the code cutoff](https://about.gitlab.com/handbook/engineering/releases/#self-managed-releases-1),
      the feature can be officially announced in a release blog post.
    - [ ] `/chatops run auto_deploy status <merge-commit-of-cleanup-mr>`
- [ ] Close [the feature issue](ISSUE LINK) to indicate the feature will be released in the current milestone.
- [ ] If not already done, clean up the feature flag from all environments by running these chatops command in `#production` channel: `/chatops run feature delete <feature-flag-name> --dev --pre --staging --staging-ref --production`
- [ ] Close this rollout issue.


/label ~"feature flag"
<!-- Uncomment the appropriate type label
/label ~"type::feature" ~"feature::addition"
/label ~"type::maintenance"
/label ~"type::bug"
-->

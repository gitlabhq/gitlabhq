<!-- Title suggestion: [Experiment Name] Successful Cleanup -->

## Summary

The experiment is currently rolled out to 100% of users and has been deemed a success.
The changes need to become an official part of the product.

## Steps

- [ ] Determine whether the feature should apply to SaaS and/or self-managed
- [ ] Determine whether the feature should apply to EE - and which tiers - and/or Core
- [ ] Determine if tracking should be kept as is, removed, or modified.
- [ ] Determine if any UX experiences need to be "polished" i.e. updated to further improve the end user experience. This task should be completed by the designated UX counterpart. 
   - [ ] (placeholder for UX polish work that needs to be completed for this cleanup issue to be considered completed) 
- [ ] Ensure any relevant documentation has been updated.
- [ ] Determine whether there are other concerns that need to be considered before removing the feature flag.
   - These are typically captured in the `Experiment Successful Cleanup Concerns` section of the rollout issue.
- [ ] Consider changes to any `feature_category:` introduced by the experiment if ownership is changing (PM for Growth and PM for the new category as DRIs)
- [ ] Check to see if the experiment introduced new design assets. Add them to the appropriate repos and document them if needed.
- [ ] Optional: Migrate experiment to a default enabled [feature flag](https://docs.gitlab.com/ee/development/feature_flags) for one milestone and add a changelog. Converting to a feature flag can be skipped at the ICs discretion if risk is deemed low with consideration to both SaaS and (if applicable) self managed
- [ ] In the next milestone, [remove the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) if applicable
- [ ] After the flag removal is deployed, [clean up the feature/experiment feature flags](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) by running chatops command in `#production` channel
- [ ] Ensure the corresponding [Experiment Rollout](https://gitlab.com/groups/gitlab-org/-/boards/1352542?label_name[]=devops%3A%3Agrowth&label_name[]=growth%20experiment&label_name[]=experiment-rollout) issue is updated

/label ~"type::maintenance" ~"workflow::scheduling" ~"growth experiment" ~"feature flag"

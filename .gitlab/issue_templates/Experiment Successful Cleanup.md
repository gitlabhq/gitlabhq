<!-- Title suggestion: [Experiment Name] Successful Cleanup -->

## Summary

The experiment is currently rolled out to 100% of users and has been deemed a success.
The changes need to become an official part of the product.

## Steps

- [ ] Determine whether the feature should apply to SaaS and/or self-managed
- [ ] Determine whether the feature should apply to EE - and which tiers - and/or Core
- [ ] Determine if tracking should be kept as is, removed, or modified.
- [ ] Ensure any relevant documentation has been updated.
- [ ] Consider changes to any `feature_category:` introduced by the experiment if ownership is changing (PM for Growth and PM for the new category as DRIs)
- [ ] Optional: Migrate experiment to a default enabled [feature flag](https://docs.gitlab.com/ee/development/feature_flags) for one milestone and add a changelog. Converting to a feature flag can be skipped at the ICs discretion if risk is deemed low with consideration to both SaaS and (if applicable) self managed
- [ ] In the next milestone, [remove the feature flag](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) if applicable
- [ ] After the flag removal is deployed, [clean up the feature/experiment feature flags](https://docs.gitlab.com/ee/development/feature_flags/controls.html#cleaning-up) by running chatops command in `#production` channel
- [ ] Ensure the corresponding [Experiment Tracking](https://gitlab.com/groups/gitlab-org/-/boards/1352542?label_name[]=devops%3A%3Agrowth&label_name[]=growth%20experiment&label_name[]=experiment%20tracking) issue is updated

/label ~"feature" ~"feature::maintenance" ~"workflow::scheduling" ~"growth experiment" ~"feature flag"  

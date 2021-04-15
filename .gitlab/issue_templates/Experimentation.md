<!-- Title suggestion: Experiment: [description] -->

# Experiment Summary
<!-- Quick rundown of what is being done -->

# Design
<!-- This should include the contexts that determine the reproducibility (stickiness) of an experiment. This means that if you want the same behavior for a user, the context would be user, or if you want all users when viewing a specific project, the context would be the project being viewed, etc. -->

# Rollout strategy
<!-- This is currently called A/B test, which isn't accurate for multi-variants. Let's call this rollout strategy. It should outline the percentages for variants and if there's more than one step to this, each of those steps and the timing for those steps (e.g. 30 days after initial rollout). -->

# Inclusions and exclusions
<!-- These would be the rules for which given context (and are limited to context or resolvable at experiment time details) is included or excluded from the test. An example of this would be to only run an experiment on groups less than N number of days old. -->

# Segmentation 
<!-- Rules for always saying context with these criteria always get this variant. For instance, if you want to always give groups less than N number of days old the experiment experience, they are specified here. This is different from the exclusion rules above. -->

# Tracking Details

- [json schema](https://gitlab.com/gitlab-org/iglu/-/blob/master/public/schemas/com.gitlab/gitlab_experiment/jsonschema/0-3-0) used in `gitlab-experiment` tracking.
- see [taxonomy](https://docs.gitlab.com/ee/development/snowplow/index.html#structured-event-taxonomy) for a guide.

| activity | category | action | label | context | property | value |
| -------- | -------- | ------ | ----- | ------- | -------- | ----- |
|  |  |  |  | json schema |  |  |

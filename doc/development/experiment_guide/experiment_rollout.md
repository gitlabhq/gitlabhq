---
stage: Growth
group: Acquisition
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Experiment rollouts and feature flags
---

## Experiment rollout issue

Each experiment should have an [experiment rollout](https://gitlab.com/groups/gitlab-org/-/boards/1352542) issue to track the experiment from rollout through to cleanup and removal.
The rollout issue is similar to a feature flag rollout issue, and is also used to track the status of an experiment.

When an experiment is deployed, the due date of the issue should be set (this depends on the experiment but can be up to a few weeks in the future).
After the deadline, the issue must be resolved and either:

- It was successful and the experiment becomes the new default.
- It was not successful and all code related to the experiment is removed.

In either case, an outcome of the experiment should be posted to the issue with the reasoning for the decision.

## Turn off all experiments

When there is a case on GitLab.com (SaaS) that necessitates turning off all experiments, we have this control.

You can toggle experiments on SaaS on and off using the `gitlab_experiment` [feature flag](../feature_flags/_index.md).

This can be done via ChatOps:

- [disable](../feature_flags/controls.md#disabling-feature-flags): `/chatops run feature set gitlab_experiment false`
- [enable](../feature_flags/controls.md#process): `/chatops run feature delete gitlab_experiment`
- This allows the `default_enabled` [value of true in the YAML](https://gitlab.com/gitlab-org/gitlab/-/blob/016430f6751b0c34abb24f74608c80a1a8268f20/config/feature_flags/ops/gitlab_experiment.yml#L8) to be honored.

## Notes on feature flags

NOTE:
We use the terms "enabled" and "disabled" here, even though it's against our
[documentation style guide recommendations](../documentation/styleguide/word_list.md#enable)
because these are the terms that the feature flag documentation uses.

You may already be familiar with the concept of feature flags in GitLab, but using
feature flags in experiments is a bit different. While in general terms, a feature flag
is viewed as being either `on` or `off`, this isn't accurate for experiments.

Generally, `off` means that when we ask if a feature flag is enabled, it always
returns `false`, and `on` means that it always returns `true`. An interim state,
considered `conditional`, also exists. We take advantage of this trinary state of
feature flags. To understand this `conditional` aspect: consider that either of these
settings puts a feature flag into this state:

- Setting a `percentage_of_actors` of any percent greater than 0%.
- Enabling it for a single user or group.

Conditional means that it returns `true` in some situations, but not all situations.

When a feature flag is disabled (meaning the state is `off`), the experiment is
considered _inactive_. You can visualize this in the [decision tree diagram](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment#how-it-works)
as reaching the first `Running?` node, and traversing the negative path.

When a feature flag is rolled out to a `percentage_of_actors` or similar (meaning the
state is `conditional`) the experiment is considered to be _running_
where sometimes the control is assigned, and sometimes the candidate is assigned.
We don't refer to this as being enabled, because that's a confusing and overloaded
term here. In the experiment terms, our experiment is _running_, and the feature flag is
`conditional`.

When a feature flag is enabled (meaning the state is `on`), the candidate is always
assigned.

We should try to be consistent with our terms, and so for experiments, we have an
_inactive_ experiment until we set the feature flag to `conditional`. After which,
our experiment is then considered _running_. If you choose to "enable" your feature flag,
you should consider the experiment to be _resolved_, because everyone is assigned
the candidate unless they've opted out of experimentation.

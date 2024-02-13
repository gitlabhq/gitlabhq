---
status: proposed
creation-date: "2023-11-01"
authors: [ "@rymai" ]
coach: "@DylanGriffith"
approvers: []
owning-stage: "~devops::non_devops"
participating-stages: []
---

# Feature Flags usage in GitLab development and operations

This blueprint builds upon [the Development Feature Flags Architecture blueprint](../feature_flags_development/index.md).

## Summary

Feature flags are critical both in developing and operating GitLab, but in the current state
of the process, they can lead to production issues, and introduce a lot of manual and maintenance work.

The goals of this blueprint is to make the process safer, more maintainable, lightweight, automated and transparent.

## Motivations

### Feature flag use-cases

Feature flags can be used for different purposes:

- De-risking GitLab.com deployments (most feature flags): Allows to quickly enable/disable
  a feature flag in production in the event of a production incident.
- Work-in-progress feature: Some features are complex and need to be implemented through several MRs. Until they're fully implemented, it needs
  to be hidden from anyone. In that case, the feature flag allows to merge all the changes to the main branch without actually using
  the feature yet.
- Beta features: We might
  [not be confident we'll be able to scale, support, and maintain a feature](https://handbook.gitlab.com/handbook/product/gitlab-the-product/#experiment-beta-ga)
  in its current form for every designed use case ([example](https://gitlab.com/gitlab-org/gitlab/-/issues/336070#note_1523983444)).
  There are also scenarios where a feature is not complete enough to be considered an MVC.
  Providing a flag in this case allows engineers and customers to disable the new feature until it's performant enough.
- Operations: Site reliability engineer or Support engineer can use these flags to
  disable potentially resource-heavy features in order to the instance back to a
  more stable and available state. Another example is SaaS-only features.
- Experiment: A/B testing on GitLab.com.
- Worker (special `ops` feature flag): Used for controlling Sidekiq workers behavior, such as deferring Sidekiq jobs.

We need to better categorize our feature flags.

### Production incidents related to feature flags

Feature flags have caused production incidents on GitLab.com ([1](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/5289), [2](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/4155), [3](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16366)).

We need to prevent this for the sake of GitLab.com stability.

### Technical debt caused by feature flags

Feature flags are also becoming an ever-growing source of technical debt: there are currently
[591 feature flags in the GitLab codebase](../../../user/feature_flags.md).

We need to reduce feature flags count for the sake of long-term maintainability & quality of the GitLab codebase.

## Goal

The goal of this blueprint is to improve the feature flag process by making it:

- safer
- more maintainable
- more lightweight & automated
- more transparent

## Challenges

### Complex feature flag rollout process

The feature flag rollout process is currently:

- Complex: Rollout issues that are very manual and includes a lot of checkboxes
  (including non-relevant checkboxes).
  Engineers often don't use these issues, which tend to become stale and forgotten over time.
- Not very transparent: Feature flag changes are logged in several places far from the rollout
  issue, which makes it hard to understand the latest feature flag state.
- Far from production processes: Rollout issues are created in the `gitlab-org/gitlab` project
  (far from the production issue tracker).
- There is no consistent path to rolling out feature flags: we leave to the judgement of the
  engineer to trade-off between speed and safety. There should be a standardized set of rollout
  steps.

### Technical debt and codebase complexity

[The challenges from the Development Feature Flags Architecture blueprint still stand](../feature_flags_development/index.md#challenges).

Additionally, there are new challenges:

- If a feature flag is enabled by default, and is disabled in an on-premise installation,
  then when the feature flag is removed, the feature suddenly becomes enabled on the
  on-premise instance and cannot be rolled backed to the previous behavior.

### Multiple source of truth for feature flag default states and observability

We currently show the feature flag default states in several places, for different intended audiences:

**GitLab customers**

- [User documentation](../../../user/feature_flags.md):
  List all feature flags and their metadata so that GitLab customers can tweak feature flags on
  their instance. Also useful for GitLab.com users that want to check the default state of a feature flag.

**Site reliability and Delivery engineers**

- [Internal GitLab.com feature flag state change issues](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues):
  For each change of a feature flag state on GitLab.com, an issue is created in this project.
- [Internal GitLab.com feature flag state change logs](https://nonprod-log.gitlab.net):
  Filter logs with `source: feature` and `env: gprd` to see feature flag state change logs.

**GitLab Engineering & Infra/Quality Directors / VPs, and CTO**

- [Internal Sisense dashboard](https://app.periscopedata.com/app/gitlab/792066/Engineering-::-Feature-Flags):
  Feature flag metrics over time, grouped per DevOps groups.

**GitLab Engineering and Product managers**

- ["Feature flags requiring attention" monthly reports](https://gitlab.com/gitlab-org/quality/triage-reports/-/issues/?sort=created_date&state=opened&search=Feature%20flags&in=TITLE&assignee_id=None&first_page_size=100):
  Same data as the above Internal Sisense dashboard but for a specific DevOps
  group, presented in an issue and assigned to the group's Engineering managers.

**Anyone who wants to check feature flag default states**

- [Unofficial feature flags dashboard](https://samdbeckham.gitlab.io/feature-flags/):
  A user-friendly dashboard which provides useful filtering.

This leads to confusion for almost all feature flag stakeholders (Development engineers, Engineering managers, Site reliability, Delivery engineers).

## Proposal

### Improve feature flags implementation and usage

- [Reduce the likelihood of mis-configuration and human-error at the implementation step](https://gitlab.com/groups/gitlab-org/-/epics/11553)
  - Remove the "percentage of time" strategy in favor of "percentage of actors"
- [Improve the feature flag development documentation](https://gitlab.com/groups/gitlab-org/-/epics/5324)

### Introduce new feature flag `type`s

It's clear that the `development` feature flag type actually includes several use-cases:

- GitLab.com deployment de-risking. YAML value: `gitlab_com_derisk`.
- Work-in-progress feature. YAML value: `wip`. Once the feature is complete, the feature flag type can be changed to `beta`
  if there still are some doubts on the scalability of the feature.
- Beta features. YAML value: `beta`.

Notes:

- These new types replace the broad `development` type, which shouldn't be used anymore in the future.
- Backward-compatibility will be kept until there's no `development` feature flags in the codebase anymore.

### Introduce constraints per feature flag type

Each feature flag type will be assigned specific constraints regarding:

- Allowed values for the `default_enabled` attribute
- Maximum Lifespan (MLS): the duration starting on the introduction of the feature flag (i.e. when it's merged into `master`).
  We don't introduce a life span that would start on the global GitLab.com enablement (or `default_enabled: true` when
  applicable) so that there's incentive to rollout and delete feature flags as quickly as possible.

The MLS will be enforced through automation, reporting & regular review meetings at the section level.

Following are the constraints for each feature flag type:

- `gitlab_com_derisk`
  - `default_enabled` **must not** be set to `true`. This kind of feature flag is meant to lower the risk on GitLab.com, thus
    there's no need to keep the flag in the codebase after it's been enabled on GitLab.com.
    **`default_enabled: true` will not have any effect for this type of feature flag.**
  - Maximum Lifespan: 2 months.
  - Additional note: This type of feature flag won't be documented in the [All feature flags in GitLab](../../../user/feature_flags.md)
    page given they're short-lived and deployment-related.
- `wip`
  - `default_enabled` **must not** be set to `true`. If needed, this type can be changed to `beta` once the feature is complete.
  - Maximum Lifespan: 4 months.
- `beta`
  - `default_enabled` can be set to `true` so that a feature can be "released" to everyone in Beta with the possibility to disable
    it in the case of scalability issues (ideally it should only be disabled for this reason on specific on-premise installations).
  - Maximum Lifespan: 6 months.
- `ops`
  - `default_enabled` can be set to `true`.
  - Maximum Lifespan: Unlimited.
  - Additional note: Remember that using this type should follow a conscious decision not to introduce an instance setting.
- `experiment`
  - `default_enabled` **must not** be set to `true`.
  - Maximum Lifespan: 6 months.

### Introduce a new `feature_issue_url` field

Keeping the URL to the original feature issue will allow automated cross-linking from the rollout
and logging issues. The new field for this information is `feature_issue_url`.

For instance:

```yaml
---
name: auto_devops_banner_disabled
feature_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/12345
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/678910
rollout_issue_url: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/9876
milestone: '16.5'
type: gitlab_com_derisk
group: group::pipeline execution
```

```yaml
---
name: ai_mr_creation
feature_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/12345
introduced_by_url: https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/14218
rollout_issue_url: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/83652
milestone: '16.3'
type: beta
group: group::code review
default_enabled: true
```

### Streamline the feature flag rollout process

1. (Process) Transition to **create rollout issues in the
   [Production issue tracker](https://gitlab.com/gitlab-com/gl-infra/production/-/issues)** and adapt the
   template to be closer to the
   [Change management issue template](https://gitlab.com/gitlab-com/gl-infra/production/-/blob/master/.gitlab/issue_templates/change_management.md)
   (see [this issue](https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2780) for inspiration)
   That way, the rollout issue would only concern the actual production changes (i.e. enablement/disablement
   of the flag on production) and should be closed as soon as the production change is confirmed to work as expected.
1. (Automation) Automate most rollout steps, such as:
     - (Done) [Let the author know that their feature has been deployed to staging / canary / production environments](https://gitlab.com/gitlab-org/quality/triage-ops/-/issues/1403)
     - (Done) [Cross-link actual feature flag state change (from Chatops project) to rollout issues](https://gitlab.com/gitlab-org/gitlab/-/issues/290770)
     - (Done) [Let the author know that their `default_enabled: true` MR has been deployed to production and that the feature flag can be removed from production](https://gitlab.com/gitlab-org/quality/triage-ops/-/merge_requests/2482)
     - Automate the creation of rollout issues when a feature flag is first introduced in a merge request,
       and provide an diff suggestion to fill the `rollout_issue_url` field (Danger)
     - Check and enforce feature flag definition constraints in merge requests (Danger)
     - Provide a diff suggestion to correct the `milestone` field when it's not the same value as
       the MR milestone (Danger)
     - Upon feature flag state change, notify on Slack the group responsible for it (chatops)
     - 7 days before the Maximum Lifespan of a feature flag is reached, automatically create a "cleanup MR" with the group label set, and
       assigned to the feature flag author (if they're still with GitLab). We could take advantage of the [automation of repetitive developer tasks](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134487)
     - Enforce Maximum Lifespan of feature flags through automated reporting & regular review at the section level
1. (Documentation/process) Ensure the rollout DRI stays online for a few hours after enabling a feature flag (ideally they'd enable the flag at the
   beginning of their day) in case of any issue with the feature flag
1. (Process) Provide a standardized set of rollout steps. Trade-offs to consider include:
    - Likelihood of errors occurring
    - Total actors (users / requests / projects / groups) affected by the feature flag rollout,
      e.g. it will be bad if 100,000 users cannot log in when we roll out for 1%
    - How long to wait between each step. Some feature flags only need to wait 10 minutes per step, some
      flags should wait 24 hours. Ideally there should be automation to actively verify there
      is no adverse effect for each step.

### Provide better SSOT for the feature flag default states and current states & state changes on GitLab.com

**GitLab customers**

- [User documentation](../../../user/feature_flags.md):
  Keep the current page but add filtering and sorting, similarly to the
  [unofficial feature flags dashboard](https://samdbeckham.gitlab.io/feature-flags/).

**Site reliability and Delivery engineers**

We [assessed the usefulness of feature flag state change logging strategies](https://gitlab.com/gitlab-org/quality/engineering-productivity/team/-/issues/309)
and it appears that both
[internal GitLab.com feature flag state change issues](https://gitlab.com/gitlab-com/gl-infra/feature-flag-log/-/issues)
and [internal GitLab.com feature flag state change logs](https://nonprod-log.gitlab.net) are useful for different
audiences.

**GitLab Engineering & Infra/Quality Directors / VPs, and CTO**

- [Internal Sisense dashboard](https://app.periscopedata.com/app/gitlab/792066/Engineering-::-Feature-Flags):
  Streamline the current dashboard to be more useful for its stakeholders.

**GitLab Engineering and Product managers**

- ["Feature flags requiring attention" monthly reports](https://gitlab.com/gitlab-org/quality/triage-reports/-/issues/?sort=created_date&state=opened&search=Feature%20flags&in=TITLE&assignee_id=None&first_page_size=100):
  Make the current reports more actionable by linking to automatically created MRs for removing feature flags as well as improving documentation and best-practices around feature flags.

## Iterations

This work is being done as part of dedicated epic:
[Improve internal usage of Feature Flags](https://gitlab.com/groups/gitlab-org/-/epics/3551).
This epic describes a meta reasons for making these changes.

## Resources

- [What Are Feature Flags?](https://launchdarkly.com/blog/what-are-feature-flags/#:~:text=Feature%20flags%20are%20a%20software,portions%20of%20code%20are%20executed)
- [Feature Flags Best Practices](https://featureflags.io/feature-flags-best-practices/)
- [Short-lived or Long-lived Flags? Explaining Feature Flag lifespans](https://configcat.com/blog/2022/07/08/how-long-should-you-keep-feature-flags/)

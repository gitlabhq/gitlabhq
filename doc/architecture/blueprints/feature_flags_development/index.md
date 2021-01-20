---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
description: 'Internal usage of Feature Flags for GitLab development'
---

# Usage of Feature Flags for GitLab development

Usage of feature flags become crucial for the development of GitLab. The
feature flags are a convenient way to ship changes early, and safely rollout
them to wide audience ensuring that feature is stable and performant.

Since the presence of feature is controlled with a dedicated condition, a
developer can decide for a best time for testing the feature, ensuring that
feature is not enable prematurely.

## Challenges

The extensive usage of feature flags poses a few challenges

- Each feature flag that we add to codebase is a ~"technical debt" as it adds a
  matrix of configurations.
- Testing each combination of feature flags is close to impossible, so we
  instead try to optimise our testing of feature flags to the most common
  scenarios.
- There's a growing challenge of maintaining a growing number of feature flags.
  We sometimes forget how our feature flags are configured or why we haven't
  yet removed the feature flag.
- The usage of feature flags can also be confusing to people outside of
  development that might not fully understand dependence of ~feature or ~bug
  fix on feature flag and how this feature flag is configured. Or if the feature
  should be announced as part of release post.
- Maintaining feature flags poses additional challenge of having to manage
  different configurations across different environments/target. We have
  different configuration of feature flags for testing, for development, for
  staging, for production and what is being shipped to our customers as part of
  on-premise offering.

## Goals

The biggest challenge today with our feature flags usage is their implicit
nature. Feature flags are part of the codebase, making them hard to understand
outside of development function.

We should aim to make our feature flag based development to be accessible to
any interested party.

- developer / engineer
  - can easily add a new feature flag, and configure it's state
  - can quickly find who to reach if touches another feature flag
  - can quickly find stale feature flags
- engineering manager
  - can understand what feature flags her/his group manages
- engineering manager and director
  - can understand how much ~"technical debt" is inflicted due to amount of feature flags that we have to manage
  - can understand how many feature flags are added and removed in each release
- product manager and documentation writer
  - can understand what features are gated by what feature flags
  - can understand if feature and thus feature flag is generally available on GitLab.com
  - can understand if feature and thus feature flag is enabled by default for on-premise installations
- delivery engineer
  - can understand what feature flags are introduced and changed between subsequent deployments
- support and reliability engineer
  - can understand how feature flags changed between releases: what feature flags become enabled, what removed
  - can quickly find relevant information about feature flag to know individuals which might help with an ongoing support request or incident

## Proposal

To help with above goals we should aim to make our feature flags usage explicit
and understood by all involved parties.

Introduce a YAML-described `feature-flags/<name-of-feature.yml>` that would
allow us to have:

1. A central place where all feature flags are documented,
1. A description of why the given feature flag was introduced,
1. A what relevant issue and merge request it was introduced by,
1. Build automated documentation with all feature flags in the codebase,
1. Track how many feature flags are per given group
1. Track how many feature flags are added and removed between releases
1. Make this information easily accessible for all
1. Allow our customers to easily discover how to enable features and quickly
   find out information what did change between different releases

### The `YAML`

```yaml
---
name: ci_disallow_to_create_merge_request_pipelines_in_target_project
introduced_by_url: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40724
rollout_issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/235119
group: group::progressive delivery
type: development
default_enabled: false
```

## Reasons

These are reason why these changes are needed:

- we have around 500 different feature flags today
- we have hard time tracking their usage
- we have ambiguous usage of feature flag with different `default_enabled:` and
  different `actors` used
- we lack a clear indication who owns what feature flag and where to find
  relevant informations
- we do not emphasise the desire to create feature flag rollout issue to
  indicate that feature flag is in fact a ~"technical debt"
- we don't know exactly what feature flags we have in our codebase
- we don't know exactly how our feature flags are configured for different
  environments: what is being used for `test`, what we ship for `on-premise`,
  what is our settings for `staging`, `qa` and `production`

## Iterations

This work is being done as part of dedicated epic: [Improve internal usage of
Feature Flags](https://gitlab.com/groups/gitlab-org/-/epics/3551). This epic
describes a meta reasons for making these changes.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|-------------------------|
| Author                       | Kamil Trzciński         |
| Architecture Evolution Coach | Gerardo Lopez-Fernandez |
| Engineering Leader           | Kamil Trzciński         |
| Domain Expert                | Shinya Maeda            |

DRIs:

| Role                         | Who
|------------------------------|------------------------|
| Product                      | Kenny Johnston         |
| Leadership                   | Craig Gomes            |
| Engineering                  | Kamil Trzciński        |

<!-- vale gitlab.Spelling = YES -->

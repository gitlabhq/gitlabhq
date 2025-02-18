---
stage: GitLab Dedicated
group: Environment Automation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Enabling features for GitLab Dedicated
---

## Versioning

GitLab Dedicated is running the n-1 GitLab version to provide sufficient run-up time to make changes across many GitLab instances, and reduce the number of releases necessary to maintain GitLab in accordance with the security maintenance policy.

GitLab Dedicated instances are automatically upgraded during scheduled maintenance windows throughout the week.

The [release rollout schedule](../administration/dedicated/maintenance.md#release-rollout-schedule) for GitLab Dedicated outlines when instances are expected to be upgraded to a new release.

## Feature flags

[Feature flags support the development and rollout of new or experimental features](https://handbook.gitlab.com/handbook/product-development-flow/feature-flag-lifecycle/#when-to-use-feature-flags) on GitLab.com. Feature flags are not tools for managing configuration.

Due to the high risk of enabling experimental features on GitLab Dedicated, and the additional workload needed to manage these on a per-instance basis, feature flags are not supported on GitLab Dedicated.

Instead, all per-instance configurations must be made using the application (UI or API) settings to allow customers to control them.

## Enabling features

All features need to be Generally Available before they can be deployed to GitLab Dedicated. In most cases, this means any feature flags are defaulted to on, and the feature is being used on GitLab.com and by users on GitLab Self-Managed.

New versions of GitLab and any other changes, are deployed using automation during scheduled maintenance windows. Because of the required automation and the timing of deployments, features must be safe for auto-rollout. This means that new features don't require any immediate manual adjustment from operators or customers.

Features that require additional configuration after they have been deployed, must have API or UI settings to allow the customer to make the necessary changes.

GitLab Dedicated is a single-tenant SaaS product. This means that one-off, customer-specific tasks cannot be supported.

Features that may not be suitable or useful for every customer must be controlled using application settings to avoid creating unsustainable workloads.

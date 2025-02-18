---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Deprecating GitLab features
---

This page includes information about how and when to remove or make breaking changes
to GitLab features.

For details about the terms used on this page, see [the terminology](../../update/terminology.md).

## Minimize the impact of breaking changes

Minimizing the impact to our customers ahead of a breaking change will ensure that disruptions will be as small as possible. Product and Engineering teams should work closely together to understand 1) who would be most impacted and how and 2) what tooling may help our users to migrate.

## Planning

If a deprecation or breaking change is unavoidable, then take the following steps:

1. Review the [deprecation guidelines in our documentation](#minimize-the-impact-of-breaking-changes)
1. Review the [breaking changes best practices](https://docs.google.com/document/d/1ByVZEhGJfjb6XTwiDeaSDRVwUiF6dsEQI01TW4BJA0k/edit?tab=t.0#heading=h.vxhro51h5zxn) (internal link)
1. Review the [release post process for announcing breaking changes](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes)
1. **(Required)** Create a [deprecation issue ticket](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Deprecations.md) and begin following the steps documented there

The [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Deprecations.md) includes checklist that ensure each breaking change has sufficiently planned for:

- Customer impact **(DRI: Engineering or Product, depending on change)**
  - Measure product usage of the feature impacted by the breaking change
  - Assess how many customers will be impacted and how, by the breaking change
- Rollout plan **(DRI: Engineering)**
  - Is there a % roll out on GitLab.com?
  - During that major milestone, when should the roll out begin?
  - And similar questions related to roll out preparedness
- Migration plan **(DRI: Engineering)**
  - Are we instrumenting usage? If so, how are we using that data to inform what users will be impacted?
  - How do we quickly and safely migrate them, preferably before the rollout?
  - Can we create tooling for users to manually migrate their own data or workflows?
  - Can we allow users to manually enable the breaking change so that they can control when it takes effect?
  - Have we automated the migration process **as much as possible** for users who do not take any manual steps to migrate.
  - Have we (optionally) created UI controls for instance admins to disable the breaking change, providing flexibility to Self-Managed / Dedicated customers to plan for their migration path?
  - And similar questions related to migration options available to customers
- Communication plan **(DRI: Product)**
  - Are customers aware of the upcoming changes?
  - Do they know when the changes will go into effect?
  - Do they know what actions to take and when?
  - Are internal stakeholders supporting affected customers aware of the upcoming changes?
  - Have we gone beyond a public announcement to ensure that customers have received and acted upon the information?
  - Have we engaged with customer-supporting teams (CS, Support, AEs, etc) to ensure that they have received and acted upon the information?
  - And similar questions related to clear and proactive communication

## When can a feature be deprecated?

Deprecations should be announced on the [Deprecated feature removal schedule](../../update/deprecations.md).

Deprecations should be announced [no later than the third milestone preceding intended removal](https://handbook.gitlab.com/handbook/product/gitlab-the-product/#process-for-deprecating-and-removing-a-feature).

Do not include the deprecation announcement in the merge request that introduces a code change for the deprecation.
Use a separate MR to create a deprecation entry. For steps to create a deprecation entry, see
[Update the deprecations doc](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc).

![Deprecation, End of Support, Removal process](img/deprecation_removal_process_v15_1.png)

## How are Community Contributions to a deprecated feature handled?

Development on deprecated features is restricted to Priority 1 / Severity 1 bug fixes. Any community contributions to deprecated features are unlikely to be prioritized during milestone planning.

However, at GitLab, we [give agency](https://handbook.gitlab.com/handbook/values/#give-agency) to our team members. So, a member of the team associated with the contribution may decide to review and merge it at their discretion.

## When can a feature be removed/changed?

Features or configuration can only be removed/changed in a major release.

They must be [deprecated in advance](https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc).

For API removals, see the [GraphQL](../../api/graphql/_index.md#deprecation-and-removal-process) and [GitLab API](../documentation/restful_api_styleguide.md#deprecations) guidelines.

For configuration removals, see the [Omnibus deprecation policy](../../administration/package_information/deprecation_policy.md).

For versioning and upgrade details, see our [Release and Maintenance policy](../../policy/maintenance.md).

## Requesting a breaking change in a minor release

GitLab Self-Managed packages are semantically versioned and follow our [maintenance policy](../../policy/maintenance.md). This process applies to features and APIs that are generally available, not beta or experimental.

This maintenance policy is in place to allow our customers to prepare for disruptive changes by establishing a clear and predictable pattern that is widely used in the software industry. For many of our customers, GitLab is a business-critical application and surprising changes can cause damages and erode trust.

Introducing breaking changes in minor releases is against policy because it can disrupt our customers and introduces an element of randomness that requires customers to check for breaking changes every minor release to ensure that their business is not impacted. This does not align with our goal [to make it as easy as possible for customers to do business with GitLab](https://handbook.gitlab.com/handbook/company/yearlies/) and is strongly discouraged.

Breaking changes are deployed to GitLab.com after they are merged into the codebase and do not respect the minor release cadence. Special care must be taken to inform the [Customer Support](https://handbook.gitlab.com/handbook/support/) and [Customer Success](https://handbook.gitlab.com/handbook/customer-success/) teams so that we can offer fast resolution to any customers that may be impacted by unexpected breaking changes.

Breaking our own policies, in particular shipping breaking changes in minor releases, is only reserved for situations in which GitLab establishes that delaying a breaking change would overall have a significantly more negative impact to customers than shipping it in a minor release. The most important lens for evaluating if an exception is granted is customer results.

Introducing a breaking change in a minor release requires a PM and EM to follow the process below to request an exception:

1. Open a new issue in the [product issue tracker using the Breaking Change Exception template](https://gitlab.com/gitlab-com/Product/-/issues/new?issuable_template=Breaking-Change-Exception)
1. Title should follow the format `Breaking change exception: Description`
1. Provide an impact assessment for the breaking change
   1. How many customers are impacted?
   1. Can we get the same outcome without a breaking-change? (that is, no removal)
   1. Can the breaking-change wait till the next major release, or the next scheduled upgrade stop, for example [Database scenarios](../database/required_stops.md))?
   1. What is the alternative for customers to do the same job the change will break?
   1. How difficult is it for customers to migrate to the alternative? Is there a migration plan?
1. Provide a communication plan and establish a clear timeline, including the targeted minor release.
1. Notify Support and Customer Success so they can share information with relevant customers.
1. Obtain approval from the VP of Development, VP of Product Management, and VP of Customer Support for this area
1. Obtain approval from the CPO and CTO

## Update the deprecations and removals documentation

The [deprecations and removals](../../update/deprecations.md)
documentation is generated from the YAML files located in
[`gitlab/data/deprecations`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations).

To update the deprecations and removals page when a YAML file is added,
edited, or removed:

1. From the command line, go to your local clone of the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project.
1. Create, edit, or remove the YAML file under [`data/deprecations`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations).
1. Compile the deprecations and removals documentation:

   ```shell
   bin/rake gitlab:docs:compile_deprecations
   ```

1. If needed, you can verify the documentation is up to date with:

   ```shell
   bin/rake gitlab:docs:check_deprecations
   ```

1. Commit the updated documentation and push the changes.
1. Create a merge request using the [Deprecations and Removals](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/merge_request_templates/Deprecations.md)
   template.

Related Handbook pages:

- <https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#deprecations-removals-and-breaking-changes>
- <https://handbook.gitlab.com/handbook/marketing/blog/release-posts/#update-the-deprecations-doc>

## Update the breaking change windows documentation

The [breaking change windows](../../update/breaking_windows.md)
documentation is generated based on the `window` value in the YAML files located in
[`gitlab/data/deprecations`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations).

To update the breaking change windows page when a YAML file is added,
edited, or removed:

1. From the command line, go to your local clone of the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) project.
1. Create, edit, or remove the YAML file under [`data/deprecations`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/data/deprecations).
1. Compile the breaking change windows documentation:

   ```shell
   bin/rake gitlab:docs:compile_windows
   ```

1. If needed, you can verify the documentation is up to date with:

   ```shell
   bin/rake gitlab:docs:check_windows
   ```

1. Commit the updated documentation and push the changes.
1. Create a merge request.

## Update the related documentation

When features are deprecated and removed, [update the related documentation](../documentation/styleguide/deprecations_and_removals.md).

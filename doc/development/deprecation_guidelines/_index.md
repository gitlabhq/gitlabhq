---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Deprecating GitLab features
---
For details about the terms used on this page, see [the terminology](../../update/terminology.md).

## Breaking Change Policy

Any change counts as a breaking change if customers need to take action to ensure their GitLab workflows aren't disrupted.

A breaking change could come from sources such as:

- An intentional product change
- A configuration update
- A third-party deprecation
- Or many other sources

For many of our users, GitLab is a tier zero system. It is critical in creating, releasing, operating, and scaling users' businesses. The consequence of a breaking change can be serious.

Product and Engineering Managers are responsible and accountable for customer impacts due to the changes they make to the platform. The burden is on GitLab, not the customer, to own change management.

**We aim to eliminate all breaking changes from GitLab.** If you have exhausted the alternatives and believe you have a strong case for why a breaking change should be allowed, you can follow the process below to seek an exception.

## How do I get approval to move forward with a breaking change?

**By default, no breaking change is allowed unless the breaking change implementation plan has been granted explicit approval by following the process below.**

1. Open an issue using the [Breaking Change Exception template](https://gitlab.com/gitlab-com/Product/-/issues/new?description_template=Breaking-Change-Exception) and fill in all of the required sections.
1. **If your breaking change meets any of the below criteria**, please call it out in the request. It doesn't guarantee the request will be approved but it helps make a good argument. Most breaking changes that are approved will fall into at least one of these categories:
   1. The impact of the breaking change has been **fully mitigated via an automated migration** that requires no action from the customer.
   1. The breaking change will have **negligible customer impact** as measured by actual product usage tracking across GitLab Self-Managed, GitLab.com, and GitLab Dedicated. For instance if it impacts less than 1% of the GitLab customer base.
   1. The breaking change is being implemented due to a **significant security risk- Severity 1 or 2.**
1. Once the issue is ready for review, follow the instructions in the template for who to tag to get the approval process started.
1. Wait until you get approval before publicly sharing the news or confirming your proposed timeline. The time from initial submission to approval or denial will vary, so **submit a minimum of six months in advance** of the proposed removal time frame.

## What details are part of the request template?

- Executive Summary
- Impact Assessment
- Rollout & Communication Plan
  - Internal Communication
  - Customer Communication

[Request template](https://gitlab.com/gitlab-com/Product/-/issues/new?description_template=Breaking-Change-Exception)

## After you have an approved breaking change, what's next?

1. Create a public [deprecation issue](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/Deprecations.md) that will serve as a source of truth for customers in regards to the change.
1. Ensure the change is added to the deprecations docs page by following the guidance below.
1. Follow the Rollout & Communications plan that was approved in your request.

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

{{< alert type="note" >}}

This process is on hold, as the breaking change windows for 19.0 have not yet been determined.
The auto-generation of the page [is disabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/207514).
When ready to start updating the page again:

- In `lib/tasks/gitlab/docs/compile_windows.rake`:
  - Uncomment the `# write_windows_content(file)` line.
  - Add new dates for the breaking change windows.
  - Update the page introduction.
  - Run `bin/rake gitlab:docs:compile_windows`.
- In `.gitlab/ci/docs.gitlab-ci.yml`
  - Uncomment the `# - bundle exec rake gitlab:docs:check_windows` line
- In: `doc/development/deprecation_guidelines/_index.md`:
  - Remove this note.

{{< /alert >}}

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

1. Update the deprecations documentation:

   ```shell
   bin/rake gitlab:docs:compile_deprecations
   ```

1. If needed, you can verify the documentation is up to date with:

   ```shell
   bin/rake gitlab:docs:check_windows
   ```

1. Commit the updated documentation and push the changes.
1. Create a merge request.

## Update the related documentation

When features are deprecated and removed, [update the related documentation](../documentation/styleguide/deprecations_and_removals.md).

## API deprecations and breaking changes

Our APIs have special rules regarding deprecations and breaking changes.

### REST API v4

REST API v4 [cannot have breaking changes made to it](../api_styleguide.md#breaking-changes)
unless the API feature was previously
[marked as experimental or beta](../api_styleguide.md#experimental-beta-and-generally-available-features).

See [What to do instead of a breaking change?](../api_styleguide.md#what-to-do-instead-of-a-breaking-change)

### GraphQL API

The GraphQL API has a requirement for a [longer deprecation cycle](../../api/graphql/_index.md#deprecation-and-removal-process)
than the standard cycle before a breaking change can be made.

See the [GraphQL deprecation process](../api_graphql_styleguide.md#deprecating-schema-items).

## Webhook breaking changes

We cannot make breaking changes to webhook payloads.

For a list of what constitutes a breaking webhook payload change and what to do instead, see the
[Webhook breaking changes guide](../../development/webhooks.md#breaking-changes).

## How are Community Contributions to a deprecated feature handled?

Development on deprecated features is restricted to Priority 1 / Severity 1 bug fixes. Any community contributions to deprecated features are unlikely to be prioritized during milestone planning.

However, at GitLab, we [give agency](https://handbook.gitlab.com/handbook/values/#give-agency) to our team members. So, a member of the team associated with the contribution may decide to review and merge it at their discretion.

## Other guidelines

For configuration removals, see the [Omnibus deprecation policy](../../administration/package_information/deprecation_policy.md).

For versioning and upgrade details, see our [Release and Maintenance policy](../../policy/maintenance.md).

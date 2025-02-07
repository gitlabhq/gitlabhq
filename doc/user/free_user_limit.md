---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Free user limit
---

DETAILS:
**Tier:** Free
**Offering:** GitLab.com

You can add up to five users to newly created top-level namespaces with
private visibility on GitLab.com.

If the namespace was created before December 28, 2022, this user limit was
applied on June 13, 2023.

Top-level private namespaces with more than five users are placed in a read-only
state. These namespaces cannot write new data to any of the following:

- Repositories
- Git Large File Storage (LFS)
- Packages
- Registries.

For the full list of restricted actions, see [read-only namespaces](read_only_namespaces.md).

User limits do not apply to users in the Free tier of:

- GitLab.com, for:
  - Public top-level groups
  - Personal namespaces, because they are public by default
  - Paid tiers
  - The following [community programs](https://about.gitlab.com/community/):
    - GitLab for Open Source
    - GitLab for Education
    - GitLab for Startups
- [Self-managed subscriptions](../subscriptions/self_managed/_index.md)

For more information, you can [talk to an expert](https://page.gitlab.com/usage_limits_help.html).

## Determine namespace user counts

Every unique user of a top-level namespace with private visibility counts towards
the five-user limit. This includes every user of a group, subgroup, and project
within a namespace.

For example, there are two groups, `example-1` and `example-2`.

The `example-1` group has:

- One group owner, `A`.
- One subgroup called `subgroup-1` with one member, `B`.
  - `subgroup-1` inherits `A` as a member from `example-1`.
- One project in `subgroup-1` called `project-1` with two members, `C` and `D`.
  - `project-1` inherits `A` and `B` as members from `subgroup-1`.

The namespace `example-1` has four unique members: `A`, `B`, `C`, and `D`, so
does not exceed the five-user limit.

The `example-2` group has:

- One group owner, `A`.
- One subgroup called `subgroup-2` with one member, `B`.
  - `subgroup-2` inherits `A` as a member from `example-2`.
- One project in `subgroup-2` called `project-2a` with two members, `C` and `D`.
  - `project-2a` inherits `A` and `B` as members from `subgroup-2`.
- One project in `subgroup-2` called `project-2b` with two members, `E` and `F`.
  - `project-2b` inherits `A` and `B` as members from `subgroup-2`.

The namespace `example-2` has six unique members: `A`, `B`, `C`, `D`, `E`, and `F`,
so it exceeds the five-user limit.

## Manage members in your group namespace

To help manage your Free user limit,
you can view and manage the total number of members across all projects and groups
in your namespace.

Prerequisites:

- You must have the Owner role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. To view all members, select the **Seats** tab.

On this page, you can view and manage all members in your namespace. For example,
to remove a member, select **Remove user**.

## Include a group in an organization's subscription

If you have multiple groups in your organization, they might have a
combination of paid (Premium or Ultimate tier) and Free tier subscriptions.
When a group with a Free tier subscription exceeds the user limit, their
namespace becomes [read-only](read_only_namespaces.md).

To remove user limits on groups with Free tier subscriptions, include those groups
in your organization's subscription:

1. To check if a group is included in the subscription,
   [view that group's subscription details](../subscriptions/gitlab_com/_index.md#view-gitlabcom-subscription).

   If the group has a Free tier subscription, it is not included in your organization's
   subscription.

1. To include a group in your paid Premium or Ultimate tier subscription,
   [transfer that group](group/manage.md#transfer-a-group) to your
   organization's top-level namespace.

If the five-user limit has been applied to your group even though you have
a paid subscription in the Premium or Ultimate tier, make sure that
[your subscription is linked](../subscriptions/gitlab_com/_index.md#link-subscription-to-a-group)
to either of the following:

- The correct top-level namespace.
- Your [Customers Portal](../subscriptions/customers_portal.md) account.

### Impact of transferred groups on subscription costs

When you transfer a group to your organization's subscription, this might
increase your seat count. This could incur additional costs for your subscription.

For example, your company has Group A and Group B:

- Group A has a paid Premium or Ultimate tier subscription and has five users.
- Group B has a Free tier subscription and has eight users, four of which are
  members of Group A.
- Group B is a read-only state because it exceeds the five-user limit.
- You transfer Group B to your company's subscription to remove the read-only state.
- Your company incurs an additional cost of four seats for the
  four members of Group B that are not members of Group A.

Users that are not part of the top-level namespace require additional seats to
remain active. For more information, see
[add seats to your subscription](../subscriptions/gitlab_com/_index.md#add-seats-to-subscription).

## Increase the five-user limit

On the Free subscription tier on GitLab.com, you cannot increase the limit of five users on
top-level groups with private visibility.

For larger teams, you should upgrade to the paid Premium or Ultimate tiers. These tiers
do not limit users and have more features to increase team productivity. For more
information, see:

- [Upgrade your subscription tier on GitLab Self-Managed](../subscriptions/self_managed/_index.md#upgrade-your-subscription-tier).
- [Upgrade your subscription tier on GitLab.com](../subscriptions/gitlab_com/_index.md#upgrade-subscription-tier).

To try the paid tiers before deciding to upgrade, start a
[free trial](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/ee/user/free_user_limit.html)
for GitLab Ultimate.

## Manage members in personal projects outside a group namespace

Personal projects are not located in top-level group namespaces. You can manage
the users in each of your personal projects, but you cannot have more than five
users in all of your personal projects.

You should [move your personal project to a group](../tutorials/move_personal_project_to_group/_index.md)
so that you can:

- Increase the amount of users to more than five.
- Purchase a paid tier subscription, additional compute minutes, or storage.
- Use [GitLab features](https://about.gitlab.com/pricing/feature-comparison/) in the group.
- Start a [free trial](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/ee/user/free_user_limit.html) for GitLab Ultimate.

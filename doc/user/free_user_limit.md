---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Free user limit

DETAILS:
**Tier:** Free
**Offering:** GitLab.com

A five-user limit applies to newly created top-level namespaces with
private visibility on GitLab.com. For existing namespaces created before December 28, 2022, the limit was applied on June 13, 2023.

When the five-user limit is applied, top-level private namespaces
exceeding the user limit are placed in a read-only state. These
namespaces cannot write new data to repositories, Git Large File
Storage (LFS), packages, or registries. For the full list of restricted
actions, see [Read-only namespaces](read_only_namespaces.md).

In the Free tier of GitLab.com, user limits do not apply to users in:

- Public top-level groups
- Paid tiers
- [Community programs](https://about.gitlab.com/community/):
  - GitLab for Open Source
  - GitLab for Education
  - GitLab for Startups

[Self-managed subscriptions](../subscriptions/self_managed/index.md) do not have user limits on the Free tier. You can also [talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

NOTE:
Personal namespaces are public by default and are excluded from the user limit.

## Determining namespace user counts

Every unique user of a top-level namespace with private visibility counts towards the five-user limit. This includes every user of a group, subgroup, and project within a namespace.

For example:

The group `example-1` has:

- One group owner, `A`.
- One subgroup called `subgroup-1` with one member, `B`.
  - `subgroup-1` inherits `A` as a member from `example-1`.
- One project in `subgroup-1` called `project-1` with two members, `C` and `D`.
  - `project-1` inherits `A` and `B` as members from `subgroup-1`.

The namespace `example-1` has four unique members: `A`, `B`, `C`, and `D`. Because `example-1` has only four unique members, it is not impacted by the five-user limit.

The group `example-2` has:

- One group owner, `A`.
- One subgroup called `subgroup-2` with one member, `B`.
  - `subgroup-2` inherits `A` as a member from `example-2`.
- One project in `subgroup-2` called `project-2a` with two members, `C` and `D`.
  - `project-2a` inherits `A` and `B` as members from `subgroup-2`.
- One project in `subgroup-2` called `project-2b` with two members, `E` and `F`.
  - `project-2b` inherits `A` and `B` as members from `subgroup-2`.

The namespace `example-2` has six unique members: `A`, `B`, `C`, `D`, `E`, and `F`. Because `example-2` has six unique users, it is impacted by the five-user limit.

## Manage members in your group namespace

To help manage your Free user limit,
you can view and manage the total number of members across all projects and groups
in your namespace.

Prerequisites:

- You must have the Owner role for the group.

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage Quotas**.
1. To view all members, select the **Seats** tab.
1. To remove a member, select **Remove user**.

If you need more time to manage your members, or to try GitLab features
with a team of more than five members, you can [start a trial](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com?&glm_content=free-user-limit-faq/ee/user/free_user_limit.html).
A trial lasts for 30 days and includes an unlimited number of members.

## Include a group in an organization's subscription

If there are multiple groups in your organization, they might have a
combination of Paid and Free subscriptions. When a group
with a Free subscription exceeds the user limit, their namespace becomes [read-only](../user/read_only_namespaces.md).

To avoid user limits on groups with Free subscriptions, you can
include them in your organization's subscription. To check if a group is included in the subscription,
[view the group's subscription details](../subscriptions/gitlab_com/index.md#view-your-gitlabcom-subscription).
If the group is on the Free tier, it is not included in your organization's subscription.

To include the group in your Paid subscription, [transfer the group](../user/group/manage.md#transfer-a-group) to your organization's
top-level namespace.

NOTE:
If you previously purchased a subscription and the 5-user limit was applied to a group,
ensure that [your subscription is linked](../subscriptions/gitlab_com/index.md#change-the-linked-namespace)
to the correct top-level namespace, or that it has been
linked to your Customers Portal account.

### Impact on seat count by transferred groups

When you transfer a group, there might be an increase in your seat count,
which could incur additional costs for your subscription.

For example, a company has Group A and Group B:

- Group A is on a Paid tier and has five users.
- Group B is on the Free tier and has eight users, four of which are members of Group A.
- Group B is placed in a read-only state when it exceeds the user limit.
- Group B is transferred to the company's subscription to remove the read-only state.
- The company incurs an additional cost of four seats for the
  four members of Group B that are not members of Group A.

Users that are not part of the top-level namespace require additional seats to remain active. For more information, see [Add seats to your subscription](../subscriptions/gitlab_com/index.md#add-seats-to-your-subscription).

## Increase the five-user limit

On the Free tier on GitLab.com, you cannot increase the limit of five users on top-level groups with private visibility.

For larger teams, you should upgrade to the Premium or Ultimate tier, which
has no user limits and offers more features to increase team productivity. To experience the
value of Paid features and unlimited users, you should start a [free trial](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com/ee/user/free_user_limit.html) for GitLab Ultimate.

## Manage members in personal projects outside a group namespace

Personal projects are not located in top-level group namespaces. You can manage the users in each of your
personal projects, but you cannot have more than five users in all of your personal projects.

You should [move your personal project to a group](../tutorials/move_personal_project_to_group/index.md) so that
you can:

- Increase the amount of users to more than five.
- Purchase a paid tier subscription, additional compute minutes, or storage.
- Use GitLab features in the group.
- Start a trial.

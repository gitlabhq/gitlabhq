---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Free user limit **(FREE SAAS)**

A five-user limit applies to newly created top-level namespaces with
private visibility on GitLab SaaS. For existing namespaces, this limit
is being rolled out gradually. Impacted users are notified in
GitLab.com at least 60 days before the limit is applied.

When the five-user limit is applied, top-level private namespaces
exceeding the user limit are placed in a read-only state. These
namespaces cannot write new data to repositories, Git Large File
Storage (LFS), packages, or registries. For the full list of restricted
actions, see [Read-only namespaces](read_only_namespaces.md).

## Manage members in your namespace

To help manage your free user limit,
you can view and manage the total number of members across all projects and groups
in your namespace.

Prerequisite:

- You must have the Owner role for the group.

1. On the top bar, select **Main menu > Groups > View all groups** and find your group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. To view all members, select the **Seats** tab.
1. To remove a member, select **Remove user**.

If you need more time to manage your members, or to try GitLab features
with a team of more than five members, you can [start a trial](https://gitlab.com/-/trial_registrations/new?glm_source=docs.gitlab.com&glm_content=free-user-limit).
A trial lasts for 30 days and includes an unlimited number of members.

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

## Related topics

- [GitLab SaaS Free tier frequently asked questions](https://about.gitlab.com/pricing/faq-efficient-free-tier/)

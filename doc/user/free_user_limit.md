---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Free user limit **(FREE SAAS)**

From October 19, 2022, namespaces in GitLab.com on the Free tier
will be limited to five (5) members per [namespace](namespace/index.md).
This limit applies to top-level private groups.

On the transition date, if your namespace has six or more unique members:

- Five members will keep a status of `Active`.
- Remaining members will get a status of `Over limit` and lose access to the
  group.
- Members invited through a group or project invitation outside of the namespace
  will be removed. You can add these members back by inviting them through their
  username or email address on the **Members** page for your group or project.

## How active members are determined

On the transition date, we'll automatically select the members who keep their `Active` status
in the following order, until we reach a total of five:

1. Members with the Owner or Maintainer role.
1. The most recently active members.

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
with a team of more than five members, you can [start a trial](https://about.gitlab.com/free-trial/).
A trial lasts for 30 days and includes an unlimited number of members.

## Related topics

- [GitLab SaaS Free tier frequently asked questions](https://about.gitlab.com/pricing/faq-efficient-free-tier/)

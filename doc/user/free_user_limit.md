---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Free user limit **(FREE SAAS)**

From October 19, 2022, a five-user limit will apply to top-level [namespaces](namespace/index.md) with private visibility on GitLab SaaS. These limits will roll out gradually, and impacted users will be notified in GitLab.com at least 60 days before the limit is applied.

When the five-user limit is applied, top-level private namespaces exceeding the user limit are placed in a read-only state. These namespaces cannot write new data to repositories, Git Large File Storage (LFS), packages, or registries.

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

## Related topics

- [GitLab SaaS Free tier frequently asked questions](https://about.gitlab.com/pricing/faq-efficient-free-tier/)

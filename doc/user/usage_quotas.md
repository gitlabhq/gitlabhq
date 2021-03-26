---
type: howto
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Storage usage quota **(FREE SAAS)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/13294) in GitLab 12.0.
> - Moved to GitLab Free.

A project's repository has a free storage quota of 10 GB. When a project's repository reaches
the quota it is locked. You cannot push changes to a locked project. To monitor the size of each
repository in a namespace, including a breakdown for each project, you can
[view storage usage](#view-storage-usage). To allow a project's repository to exceed the free quota
you must purchase additional storage. For more details, see [Excess storage usage](#excess-storage-usage).

## View storage usage

To help manage storage, a namespace's owner can view:

- Total storage used in the namespace
- Total storage used per project

To view storage usage, from the namespace's page go to **Settings > Usage Quotas** and select the
**Storage** tab. The Usage Quotas statistics are updated every 90 minutes.

If your namespace shows `N/A` as the total storage usage, push a commit to any project in that
namespace to trigger a recalculation.

A stacked bar graph shows the proportional storage used for the namespace, including a total per
storage item. Click on each project's title to see a breakdown per storage item.

## Storage usage statistics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/247831) in GitLab 13.7.
> - It's [deployed behind a feature flag](../user/feature_flags.md), enabled by default.
> - It's enabled on GitLab SaaS.
> - It's recommended for production use.

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

The following storage usage statistics are available to an owner:

- Total namespace storage used: Total amount of storage used across projects in this namespace.
- Total excess storage used: Total amount of storage used that exceeds their allocated storage.
- Purchased storage available: Total storage that has been purchased but is not yet used.

## Excess storage usage

Excess storage usage is the amount that a project's repository exceeds the free storage quota. If no
purchased storage is available the project is locked. You cannot push changes to a locked project.
To unlock a project you must [purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage)
for the namespace. When the purchase is completed, locked projects are automatically unlocked. The
amount of purchased storage available must always be greater than zero.

The **Storage** tab of the **Usage Quotas** page warns you of the following:

- Purchased storage available is running low.
- Projects that are at risk of being locked if purchased storage available is zero.
- Projects that are locked because purchased storage available is zero. Locked projects are
  marked with an information icon (**{information-o}**) beside their name.

### Excess storage example

The following example describes an excess storage scenario for namespace _Example Company_:

| Repository | Storage used | Excess storage | Quota  | Status            |
|------------|--------------|----------------|--------|-------------------|
| Red        | 10 GB        | 0 GB           | 10 GB  | Locked **{lock}** |
| Blue       | 8 GB         | 0 GB           | 10 GB  | Not locked        |
| Green      | 10 GB        | 0 GB           | 10 GB  | Locked **{lock}** |
| Yellow     | 2 GB         | 0 GB           | 10 GB  | Not locked        |
| **Totals** | **30 GB**    | **0 GB**       | -      | -                 |

The Red and Green projects are locked because their repositories have reached the quota. In this
example, no additional storage has yet been purchased.

To unlock the Red and Green projects, 50 GB additional storage is purchased.

Assuming the Green and Red projects' repositories grow past the 10 GB quota, the purchased storage
available decreases. All projects remain unlocked because 40 GB purchased storage is available:
50 GB (purchased storage) - 10 GB (total excess storage used).

| Repository | Storage used | Excess storage | Quota   | Status            |
|------------|--------------|----------------|---------|-------------------|
| Red        | 15 GB        | 5 GB           | 10 GB   | Not locked        |
| Blue       | 14 GB        | 4 GB           | 10 GB   | Not locked        |
| Green      | 11 GB        | 1 GB           | 10 GB   | Not locked        |
| Yellow     | 5 GB         | 0 GB           | 10 GB   | Not locked        |
| **Totals** | **45 GB**    | **10 GB**      | -       | -                 |

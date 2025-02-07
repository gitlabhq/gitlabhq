---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Storage
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

All projects on GitLab.com have 10 GiB of free storage for their Git repository and Large File Storage (LFS).

When a project's repository and LFS exceed 10 GiB, the project is set to a read-only state.
You cannot push changes to a read-only project. To increase storage of the project's repository and LFS to more than 10 GiB,
you must [purchase more storage](../subscriptions/gitlab_com/_index.md#purchase-more-storage).

Only the project's repository and LFS are included in the storage limit. The container registry, package registry, and build artifacts are not included in the limit.

## View storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can view the following statistics for storage usage in projects and namespaces:

- Storage usage that exceeds the GitLab.com storage limit or [self-managed storage limits](../administration/settings/account_and_limit_settings.md#repository-size-limit).
- Available purchased storage for GitLab.com.

Prerequisites:

- To view storage usage for a project, you must have at least the Maintainer role for the project or Owner role for the namespace.
- To view storage usage for a group namespace, you must have the Owner role for the namespace.

To view storage:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Usage Quotas**.
1. Select the **Storage** tab to see namespace storage usage.
1. To view storage usage for a project, in the table at the bottom, select a project. Storage usage is updated every 90 minutes.

If your namespace shows `'Not applicable.'`, push a commit to any project in the
namespace to recalculate the storage.

Storage and network usage is calculated with the binary measurement system (1024 unit multiples).
Storage usage is displayed in kibibytes (KiB), mebibytes (MiB),
or gibibytes (GiB). 1 KiB is 2^10 bytes (1024 bytes),
1 MiB is 2^20 bytes (1024 kibibytes), and 1 GiB is 2^30 bytes (1024 mebibytes).

NOTE:
Storage usage labels are being transitioned from `KB` to `KiB`, `MB` to `MiB`, and `GB` to `GiB`. During this transition,
you might see references to `KB`, `MB`, and `GB` in the UI and documentation.

## View project fork storage usage

A cost factor is applied to the storage consumed by project forks so that forks consume less namespace storage than their actual size. The cost factors for forks storage reduction applies only to namespace storage. It does not apply to project repository storage limits.

To view the amount of namespace storage the fork has used:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Usage Quotas**.
1. Select the **Storage** tab. The **Total** column displays the amount of namespace storage used by the fork as a portion of the actual size of the fork on disk.

The cost factor applies to the project repository, LFS objects, job artifacts, packages, snippets, and the wiki.

The cost factor does not apply to private forks in namespaces on the Free plan.

## Excess storage usage

Excess storage usage is the amount that exceeds the 10 GiB free storage of a project's repository and LFS. If no purchased storage is available,
the project is set to a read-only state. You cannot push changes to a read-only project.

To remove the read-only state, you must [purchase more storage](../subscriptions/gitlab_com/_index.md#purchase-more-storage)
for the namespace. After the purchase has completed, the read-only state is removed and projects are automatically
restored. The amount of available purchased storage must always
be greater than zero.

The **Storage** tab of the **Usage Quotas** page displays the following:

- Purchased storage available is running low.
- Projects that are at risk of becoming read-only if purchased storage available is zero.
- Projects that are read-only because purchased storage available is zero. Read-only projects are
  marked with an information icon (**{information-o}**) beside their name.

The total storage includes the free and excess storage purchased.
The remaining excess storage is expressed as a percentage and calculated as:
100 % - ((excess storage used - excess storage purchased) * 100).

### Excess storage example

The following example describes an excess storage scenario for projects in a namespace:

| Repository | Storage used | Excess storage | Quota  | Status               |
|------------|--------------|----------------|--------|----------------------|
| Red        | 10 GiB        | 0 GiB           | 10 GiB  | Read-only **{lock}** |
| Blue       | 8 GiB         | 0 GiB           | 10 GiB  | Not read-only        |
| Green      | 10 GiB        | 0 GiB           | 10 GiB  | Read-only **{lock}** |
| Yellow     | 2 GiB         | 0 GiB           | 10 GiB  | Not read-only        |
| **Totals** | **30 GiB**    | **0 GiB**       | -      | -                    |

The Red and Green projects are read-only because their repositories and LFS have reached the quota. In this
example, no additional storage has yet been purchased.

To remove the read-only state from the Red and Green projects, 50 GiB additional storage is purchased.

If some projects' repositories and LFS grow past the 10 GiB quota, the available purchased storage decreases.

| Repository | Storage used | Excess storage | Quota   | Status            |
|------------|--------------|----------------|---------|-------------------|
| Red        | 15 GiB        | 5 GiB         | 10 GiB  | Not read-only     |
| Blue       | 14 GiB        | 4 GiB         | 10 GiB  | Not read-only     |
| Green      | 11 GiB        | 1 GiB         | 10 GiB  | Not read-only     |
| Yellow     | 5 GiB         | 0 GiB         | 10 GiB  | Not read-only     |
| **Totals** | **45 GiB**    | **10 GiB**    | -       | -                 |

In this example:

- Available purchased storage is 40 GiB: 50 GiB (purchased storage) - 10 GiB (total excess storage used). Consequently, the projects are no longer read-only.
- Excess storage usage is 20%: 10 GiB / 50 GiB * 100.
- Remaining purchased storage is 80%.

## Manage storage usage

To manage your storage, if you are a namespace Owner, you can [purchase more storage for the namespace](../subscriptions/gitlab_com/_index.md#purchase-more-storage).

Depending on your role, you can also use the following methods to manage or reduce your storage:

- [Reduce repository size](project/repository/repository_size.md#methods-to-reduce-repository-size).

To automate storage usage analysis and management, see [storage management automation](storage_management_automation.md).

In addition to managing your storage usage you can consider these options for increased consumables:

- If you are eligible, apply for a [community program subscription](../subscriptions/community_programs.md):
  - GitLab for Education
  - GitLab for Open Source
  - GitLab for Startups
- Consider a [self-managed subscription](../subscriptions/self_managed/_index.md), which does not have storage limits.
- [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

## Related topics

- [Automate storage management](storage_management_automation.md)
- [Purchase storage](../subscriptions/gitlab_com/_index.md#purchase-more-storage)

---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

All projects on GitLab SaaS have 10 GiB of free storage for their Git repository and Large File Storage (LFS).

When a project's repository and LFS exceed 10 GiB, the project is set to a read-only state.
You cannot push changes to a read-only project. To increase storage of the project's repository and LFS to more than 10 GiB,
you must [purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer).

GitLab plans to introduce storage limits for namespaces on GitLab SaaS. After these storage limits have been applied,
storage usage will be calculated across the entire namespace and project storage limits will no longer apply.

## View storage

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can view the following statistics for storage usage in projects and namespaces:

- Storage usage that exceeds the GitLab SaaS storage limit or [self-managed storage limits](../administration/settings/account_and_limit_settings.md#repository-size-limit).
- Available purchased storage for GitLab SaaS.

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

A cost factor is applied to the storage consumed by project forks so that forks consume less namespace storage than their actual size.

To view the amount of namespace storage the fork has used:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Usage Quotas**.
1. Select the **Storage** tab. The **Total** column displays the amount of namespace storage used by the fork as a portion of the actual size of the fork on disk.

The cost factor applies to the project repository, LFS objects, job artifacts, packages, snippets, and the wiki.

The cost factor does not apply to private forks in namespaces on the Free plan.

## Excess storage usage

Excess storage usage is the amount that exceeds the 10 GiB free storage of a project's repository and LFS. If no purchased storage is available,
the project is set to a read-only state. You cannot push changes to a read-only project.

To remove the read-only state, you must [purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer)
for the namespace. After the purchase has completed, the read-only state is removed and projects are automatically
restored. The amount of available purchased storage must always
be greater than zero.

The **Storage** tab of the **Usage Quotas** page displays the following:

- Purchased storage available is running low.
- Projects that are at risk of becoming read-only if purchased storage available is zero.
- Projects that are read-only because purchased storage available is zero. Read-only projects are
  marked with an information icon (**{information-o}**) beside their name.

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

Assuming the Green and Red projects' repositories and LFS grow past the 10 GiB quota, the purchased storage
available decreases. All projects no longer have the read-only status because 40 GiB purchased storage is available:
50 GiB (purchased storage) - 10 GiB (total excess storage used).

| Repository | Storage used | Excess storage | Quota   | Status            |
|------------|--------------|----------------|---------|-------------------|
| Red        | 15 GiB        | 5 GiB           | 10 GiB   | Not read-only     |
| Blue       | 14 GiB        | 4 GiB           | 10 GiB   | Not read-only     |
| Green      | 11 GiB        | 1 GiB           | 10 GiB   | Not read-only     |
| Yellow     | 5 GiB         | 0 GiB           | 10 GiB   | Not read-only     |
| **Totals** | **45 GiB**    | **10 GiB**      | -       | -                 |

## Namespace storage limit

GitLab plans to introduce the following storage limits per top-level group:

| Subscription tier     | Storage limit |
|-----------------------|---------------|
| Free                  | 5 GiB          |
| Premium               | 50 GiB         |
| Ultimate | 250 GiB <sup>1</sup>        |

<html>
<small>
  <ol>
    <li>Applies to GitLab Trial, GitLab for Open Source, GitLab for Education, and GitLab for Startups.</li>
  </ol>
</small>
</html>

If you have a multi-year contract for GitLab Premium or Ultimate, storage limits will not apply until your first renewal after GitLab introduces the namespace storage limits.

Any additional storage you purchase before the introduction of namespace storage limits, including additional storage purchased due to project storage limits, will apply to the top-level group.

Namespaces have a 10 GiB project limit with
a soft limit on namespace storage. After GitLab applies namespace storage limits,
soft limits will become hard limits and your namespace will be [read-only](../user/read_only_namespaces.md).

To prevent your namespace from becoming read-only:

- Manage your storage usage.
- [Purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer).
- If you are eligible, apply for a [community program subscription](../subscriptions/community_programs.md):
  - GitLab for Education
  - GitLab for Open Source
  - GitLab for Startups
- If you have GitLab Free, [start a trial](https://about.gitlab.com/free-trial/) or upgrade to [GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), which has higher storage limits and more features.
- Consider a self-managed subscription, which does not have storage limits.
- [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

### Storage types in namespace storage usage

Storage types that count toward the total namespace storage are:

- Git repository
- Git LFS
- Job artifacts
- Container registry
- Package registry
- Dependency proxy
- Wiki
- Snippets

### Excess storage notifications

Storage limits are included in GitLab subscription terms but do not apply. At least 60 days before GitLab introduces storage limits,
GitLab will notify you of namespaces that exceed, or are close to exceeding, the storage limit.

- In the command-line interface, a notification displays after each `git push`
  action when your namespace has reached between 95% and 100% of your namespace storage quota.
- In the GitLab UI, a notification displays when your namespace has reached between
  75% and 100% of your namespace storage quota.
- GitLab sends an email to members with the Owner role to notify them when namespace
  storage usage is at 70%, 85%, 95%, and 100%.

## Manage storage usage

To manage your storage, if you are a namespace Owner, you can [purchase more storage for the namespace](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer).

Depending on your role, you can also use the following methods to manage or reduce your storage:

- [Reduce package registry storage](packages/package_registry/reduce_package_registry_storage.md).
- [Reduce dependency proxy storage](packages/dependency_proxy/reduce_dependency_proxy_storage.md).
- [Reduce repository size](project/repository/reducing_the_repo_size_using_git.md).
- [Reduce container registry storage](packages/container_registry/reduce_container_registry_storage.md).
- [Reduce wiki repository size](../administration/wikis/index.md#reduce-wiki-repository-size).
- [Manage artifact expiration period](../ci/yaml/index.md#artifactsexpire_in).
- [Reduce build artifact storage](../ci/jobs/job_artifacts.md#delete-job-log-and-artifacts).

To automate storage usage analysis and management, see [storage management automation](storage_management_automation.md).

## Related Topics

- [Automate storage management](storage_management_automation.md)
- [Purchase storage and transfer](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer)
- [Transfer usage](packages/container_registry/reduce_container_registry_data_transfer.md)

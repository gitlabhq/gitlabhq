---
type: howto
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Storage **(FREE ALL)**

Storage usage statistics are available for projects and namespaces. You can use that information to
manage storage usage within the applicable quotas.

Statistics include:

- Storage usage across projects in a namespace.
- Storage usage that exceeds the storage SaaS limit or [self-managed storage quota](../administration/settings/account_and_limit_settings.md#repository-size-limit).
- Available purchased storage for SaaS.

Storage and network usage are calculated with the binary measurement system (1024 unit multiples).
Storage usage is displayed in kibibytes (KiB), mebibytes (MiB),
or gibibytes (GiB). 1 KiB is 2^10 bytes (1024 bytes),
1 MiB is 2^20 bytes (1024 kibibytes), 1 GiB is 2^30 bytes (1024 mebibytes).

NOTE:
Storage usage labels are being transitioned from `KB` to `KiB`, `MB` to `MiB`, and `GB` to `GiB`. During this transition,
you might see references to `KB`, `MB`, and `GB` in the UI and documentation.

## View storage usage

Prerequisites:

- To view storage usage for a project, you must have at least the Maintainer role for the project or Owner role for the namespace.
- To view storage usage for a group namespace, you must have the Owner role for the namespace.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select the **Storage** tab to see namespace storage usage.
1. To view storage usage for a project, select one of the projects from the table at the bottom of the **Storage** tab of the **Usage Quotas** page.

The information on the **Usage Quotas** page is updated every 90 minutes.

If your namespace shows `'Not applicable.'`, push a commit to any project in the
namespace to recalculate the storage.

### View project fork storage usage **(FREE SAAS)**

A cost factor is applied to the storage consumed by project forks so that forks consume less namespace storage than their actual size.

To view the amount of namespace storage the fork has used:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. On the left sidebar, select **Settings > Usage Quotas**.
1. Select the **Storage** tab. The **Total** column displays the amount of namespace storage used by the fork as a portion of the actual size of the fork on disk.

The cost factor applies to the project repository, LFS objects, job artifacts, packages, snippets, and the wiki.

The cost factor does not apply to private forks in namespaces on the Free plan.

## Manage storage usage

To manage your storage, if you are a namespace Owner you can [purchase more storage for the namespace](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer).

Depending on your role, you can also use the following methods to manage or reduce your storage:

- [Reduce package registry storage](packages/package_registry/reduce_package_registry_storage.md).
- [Reduce dependency proxy storage](packages/dependency_proxy/reduce_dependency_proxy_storage.md).
- [Reduce repository size](project/repository/reducing_the_repo_size_using_git.md).
- [Reduce container registry storage](packages/container_registry/reduce_container_registry_storage.md).
- [Reduce wiki repository size](../administration/wikis/index.md#reduce-wiki-repository-size).
- [Manage artifact expiration period](../ci/yaml/index.md#artifactsexpire_in).
- [Reduce build artifact storage](../ci/jobs/job_artifacts.md#delete-job-log-and-artifacts).

To automate storage usage analysis and management, see the [storage management automation](storage_management_automation.md) documentation.

## Set usage quotas **(FREE SELF)**

There are no application limits on the amount of storage and transfer for self-managed instances. The administrators are responsible for the underlying infrastructure costs. Administrators can set [repository size limits](../administration/settings/account_and_limit_settings.md#repository-size-limit) to manage your repositories’ size.

## Storage limits **(FREE SAAS)**

### Project storage limit

Projects on GitLab SaaS have a 10 GiB storage limit on their Git repository and LFS storage. Limits on project storage
will be removed before limits are applied to GitLab SaaS namespace storage in the future.

When a project's repository and LFS reaches the quota, the project is set to a read-only state.
You cannot push changes to a read-only project. To monitor the size of each
repository in a namespace, including a breakdown for each project,
[view storage usage](#view-storage-usage). To allow a project's repository and LFS to exceed the free quota
you must purchase additional storage. For more details, see [Excess storage usage](#excess-storage-usage).

#### Excess storage usage

Excess storage usage is the amount that a project's repository and LFS exceeds the [project storage limit](#project-storage-limit). If no
purchased storage is available the project is set to a read-only state. You cannot push changes to a read-only project.
To remove the read-only state you must [purchase more storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer)
for the namespace. When the purchase is completed, read-only projects are automatically restored to their standard state. The
amount of purchased storage available must always be greater than zero.

The **Storage** tab of the **Usage Quotas** page warns you of the following:

- Purchased storage available is running low.
- Projects that are at risk of becoming read-only if purchased storage available is zero.
- Projects that are read-only because purchased storage available is zero. Read-only projects are
  marked with an information icon (**{information-o}**) beside their name.

#### Excess storage example

The following example describes an excess storage scenario for a namespace:

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

### Namespace storage limit **(FREE SAAS)**

GitLab plans to enforce a storage limit for namespaces on GitLab SaaS. For more information, see
the FAQs for the following tiers:

- [Free tier](https://about.gitlab.com/pricing/faq-efficient-free-tier/#storage-limits-on-gitlab-saas-free-tier).
- [Premium and Ultimate](https://about.gitlab.com/pricing/faq-paid-storage-transfer/).

Namespaces on GitLab SaaS have a [10 GiB project limit](#project-storage-limit) with a soft limit on
namespace storage. Soft storage limits are limits that have not yet been enforced by GitLab, and will become
hard limits after namespace storage limits apply. To avoid your namespace from becoming
[read-only](../user/read_only_namespaces.md) after namespace storage limits apply,
you should ensure that your namespace storage adheres to the soft storage limit.

Namespace storage limits do not apply to self-managed deployments, but administrators can [manage the repository size](../administration/settings/account_and_limit_settings.md#repository-size-limit).

Storage types that add to the total namespace storage are:

- Git repository
- Git LFS
- Job artifacts
- Container registry
- Package registry
- Dependency proxy
- Wiki
- Snippets

If your total namespace storage exceeds the available namespace storage quota, all projects under the namespace become read-only. Your ability to write new data is restricted until the read-only state is removed. For more information, see [Restricted actions](../user/read_only_namespaces.md#restricted-actions).

To notify you that you have nearly exceeded your namespace storage quota:

- In the command-line interface, a notification displays after each `git push` action when your namespace has reached between 95% and 100%+ of your namespace storage quota.
- In the GitLab UI, a notification displays when your namespace has reached between 75% and 100%+ of your namespace storage quota.
- GitLab sends an email to members with the Owner role to notify them when namespace storage usage is at 70%, 85%, 95%, and 100%.

To prevent exceeding the namespace storage limit, you can:

- [Manage your storage usage](#manage-storage-usage).
- If you meet the eligibility requirements, you can apply for:
  - [GitLab for Education](https://about.gitlab.com/solutions/education/join/)
  - [GitLab for Open Source](https://about.gitlab.com/solutions/open-source/join/)
  - [GitLab for Startups](https://about.gitlab.com/solutions/startups/)
- Consider using a [self-managed instance](../subscriptions/self_managed/index.md) of GitLab, which does not have these limits on the Free tier.
- [Purchase additional storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer) units at $60 per year for 10 GiB of storage.
- [Start a trial](https://about.gitlab.com/free-trial/) or [upgrade to GitLab Premium or Ultimate](https://about.gitlab.com/pricing/), which include higher limits and features to enable growing teams to ship faster without sacrificing on quality.
- [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

## Related Topics

- [Automate storage management](storage_management_automation.md)
- [Purchase storage and transfer](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer)
- [Transfer usage](packages/container_registry/reduce_container_registry_data_transfer.md)

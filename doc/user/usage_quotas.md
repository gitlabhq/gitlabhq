---
type: howto
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Storage usage quota **(FREE)**

Storage usage statistics are available for projects and namespaces. You can use that information to
manage storage usage within the applicable quotas.

Statistics include:

- Storage usage across projects in a namespace.
- Storage usage that exceeds the storage quota.
- Available purchased storage.

## View storage usage

Prerequisites:

- To view storage usage for a project, you must have at least the Maintainer role for the project or Owner role for the namespace.
- To view storage usage for a namespace, you must have the Owner role for the namespace.

1. Go to your project or namespace:
   - For a project, on the top bar, select **Main menu > Projects** and find your project.
   - For a namespace, enter the URL in your browser's toolbar.
1. From the left sidebar, select **Settings > Usage Quotas**.
1. Select the **Storage** tab.

Select any title to view details. The information on this page
is updated every 90 minutes.

If your namespace shows `'Not applicable.'`, push a commit to any project in the
namespace to recalculate the storage.

### Container Registry usage **(FREE SAAS)**

Container Registry usage is available only for GitLab.com. This feature requires a
[new version](https://about.gitlab.com/blog/2022/04/12/next-generation-container-registry/)
of the GitLab Container Registry. To learn about the proposed release for self-managed
installations, see [epic 5521](https://gitlab.com/groups/gitlab-org/-/epics/5521).

### Storage usage statistics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/68898) project-level graph in GitLab 14.4 [with a flag](../administration/feature_flags.md) named `project_storage_ui`. Disabled by default.
> - Enabled on GitLab.com in GitLab 14.4.
> - Enabled on self-managed in GitLab 14.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71270) in GitLab 14.5.

The following storage usage statistics are available to a maintainer:

- Total namespace storage used: Total amount of storage used across projects in this namespace.
- Total excess storage used: Total amount of storage used that exceeds their allocated storage.
- Purchased storage available: Total storage that has been purchased but is not yet used.

## Manage your storage usage

To manage your storage, if you are a namespace Owner you can [purchase more storage for the namespace](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer).

Depending on your role, you can also use the following methods to manage or reduce your storage:

- [Reduce package registry storage](packages/package_registry/reduce_package_registry_storage.md).
- [Reduce dependency proxy storage](packages/dependency_proxy/reduce_dependency_proxy_storage.md).
- [Reduce repository size](project/repository/reducing_the_repo_size_using_git.md).
- [Reduce container registry storage](packages/container_registry/reduce_container_registry_storage.md).
- [Reduce wiki repository size](../administration/wikis/index.md#reduce-wiki-repository-size).

## Manage your transfer usage

Depending on your role, to manage your transfer usage you can [reduce Container Registry data transfers](packages/container_registry/reduce_container_registry_data_transfer.md).

## Project storage limit

Projects on GitLab SaaS have a 10 GB storage limit on their Git repository and LFS storage.
After namespace-level storage limits are applied, the project limit is removed. A namespace has either a namespace-level storage limit or a project-level storage limit, but not both.

When a project's repository and LFS reaches the quota, the project is set to a read-only state.
You cannot push changes to a read-only project. To monitor the size of each
repository in a namespace, including a breakdown for each project,
[view storage usage](#view-storage-usage). To allow a project's repository and LFS to exceed the free quota
you must purchase additional storage. For more details, see [Excess storage usage](#excess-storage-usage).

### Excess storage usage

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
| Red        | 10 GB        | 0 GB           | 10 GB  | Read-only **{lock}** |
| Blue       | 8 GB         | 0 GB           | 10 GB  | Not read-only        |
| Green      | 10 GB        | 0 GB           | 10 GB  | Read-only **{lock}** |
| Yellow     | 2 GB         | 0 GB           | 10 GB  | Not read-only        |
| **Totals** | **30 GB**    | **0 GB**       | -      | -                    |

The Red and Green projects are read-only because their repositories and LFS have reached the quota. In this
example, no additional storage has yet been purchased.

To remove the read-only state from the Red and Green projects, 50 GB additional storage is purchased.

Assuming the Green and Red projects' repositories and LFS grow past the 10 GB quota, the purchased storage
available decreases. All projects remain read-only because 40 GB purchased storage is available:
50 GB (purchased storage) - 10 GB (total excess storage used).

| Repository | Storage used | Excess storage | Quota   | Status            |
|------------|--------------|----------------|---------|-------------------|
| Red        | 15 GB        | 5 GB           | 10 GB   | Not read-only     |
| Blue       | 14 GB        | 4 GB           | 10 GB   | Not read-only     |
| Green      | 11 GB        | 1 GB           | 10 GB   | Not read-only     |
| Yellow     | 5 GB         | 0 GB           | 10 GB   | Not read-only     |
| **Totals** | **45 GB**    | **10 GB**      | -       | -                 |

## Namespace storage limit

Namespaces on GitLab SaaS have a storage limit. For more information, see our [pricing page](https://about.gitlab.com/pricing/).
This limit is not visible on the **Usage quotas** page, but is prior to the limit being [applied](#namespace-storage-limit-application-schedule). Self-managed deployments are not affected.

Storage types that add to the total namespace storage are:

- Git repository
- Git LFS
- Artifacts
- Container registry
- Package registry
- Dependency proxy
- Wiki
- Snippets

If your total namespace storage exceeds the available namespace storage quota, all projects under the namespace become read-only. Your ability to write new data is restricted until the read-only state is removed. For more information, see [Restricted actions](../user/read_only_namespaces.md#restricted-actions).

To notify you that you have nearly exceeded your namespace storage quota:

- In the command line interface, a notification displays after each `git push` action when you've reached 95% and 100% of your namespace storage quota.
- In the GitLab UI, a notification displays when you've reached 75%, 95%, and 100% of your namespace storage quota.
- GitLab sends an email to members with the Owner role to notify them when namespace storage usage is at 70%, 85%, 95%, and 100%.

To prevent exceeding the namespace storage quota, you can:

- Reduce storage consumption by following the suggestions in the [Manage Your Storage Usage](#manage-your-storage-usage) section of this page.
- Apply for [GitLab for Education](https://about.gitlab.com/solutions/education/join/), [GitLab for Open Source](https://about.gitlab.com/solutions/open-source/join/), or [GitLab for Startups](https://about.gitlab.com/solutions/startups/) if you meet the eligibility requirements.
- Consider using a [self-managed instance](../subscriptions/self_managed/index.md) of GitLab which does not have these limits on the free tier.
- [Purchase additional storage](../subscriptions/gitlab_com/index.md#purchase-more-storage-and-transfer) units at $60/year for 10 GB of storage.
- [Start a trial](https://about.gitlab.com/free-trial/) or [upgrade to GitLab Premium or Ultimate](https://about.gitlab.com/pricing/) which include higher limits and features that enable growing teams to ship faster without sacrificing on quality.
- [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

### Namespace storage limit application schedule

Information on when namespace-level storage limits are applied is available on these FAQ pages for the [Free](https://about.gitlab.com/pricing/faq-efficient-free-tier/#storage-limits-on-gitlab-saas-free-tier) and [Paid](https://about.gitlab.com/pricing/faq-paid-storage-transfer/) tier.

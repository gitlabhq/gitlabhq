---
stage: Fulfillment
group: Utilization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Storage
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

## Free limit

{{< details >}}

- Tier: Free

{{< /details >}}

Each project in a Free tier namespace on GitLab.com has 10 GiB of free storage for its Git repository and Large File Storage (LFS).

When a project's repository and LFS exceed 10 GiB, the project is set to a read-only state.
You cannot push changes to a read-only project.
To increase storage of the project's repository and LFS to more than 10 GiB,
you must purchase more storage.

Only the project's repository and LFS are included in the storage limit.
The container registry, package registry, and build artifacts are not included in the limit.

## View storage

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can view the following statistics for storage usage in projects and namespaces:

- Storage usage that exceeds the GitLab.com storage limit or [GitLab Self-Managed storage limits](../administration/settings/account_and_limit_settings.md#repository-size-limit).
- Available purchased storage for GitLab.com.

Prerequisites:

- To view storage usage for a project, you must have at least the Maintainer role for the project or Owner role for the namespace.
- To view storage usage for a group namespace, you must have the Owner role for the namespace.

To view storage:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Usage quotas**.
1. Select the **Storage** tab to see namespace storage usage.
1. To view storage usage for a project, in the table at the bottom, select a project. Storage usage is updated every 90 minutes.

If your namespace shows `'Not applicable.'`, push a commit to any project in the
namespace to recalculate the storage.

Storage and network usage is calculated with the binary measurement system (1024 unit multiples).
Storage usage is displayed in kibibytes (KiB), mebibytes (MiB),
or gibibytes (GiB). 1 KiB is 2<sup>10</sup> bytes (1024 bytes),
1 MiB is 2<sup>20</sup> bytes (1024 kibibytes), and 1 GiB is 2<sup>30</sup> bytes (1024 mebibytes).

## View project fork storage usage

A cost factor is applied to the storage consumed by project forks so that forks consume less namespace storage than their actual size. The cost factors for forks storage reduction applies only to namespace storage. It does not apply to project repository storage limits.

To view the amount of namespace storage the fork has used:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Settings > Usage quotas**.
1. Select the **Storage** tab. The **Total** column displays the amount of namespace storage used by the fork as a portion of the actual size of the fork on disk.

The cost factor applies to the project repository, LFS objects, job artifacts, packages, snippets, and the wiki.

The cost factor does not apply to private forks in namespaces on the Free plan.

## Excess storage usage

{{< details >}}

- Tier: Free

{{< /details >}}

Excess storage usage is the amount that exceeds the 10 GiB free storage of a project's repository and LFS. If no purchased storage is available,
the project is set to a read-only state. You cannot push changes to a read-only project.

To remove the read-only state, you must purchase more storage for the namespace.
After the purchase has completed, the read-only state is removed and projects are automatically
restored. The amount of available purchased storage must always
be greater than zero.

The **Storage** tab of the **Usage quotas** page displays the following:

- Purchased storage available is running low.
- Projects that are at risk of becoming read-only if purchased storage available is zero.
- Projects that are read-only because purchased storage available is zero. Read-only projects are
  marked with an information icon ({{< icon name="information-o" >}}) beside their name.

The total storage includes the free and excess storage purchased.
The remaining excess storage is expressed as a percentage and calculated as:
100 % - ((excess storage used - excess storage purchased) × 100).

### Excess storage example

The following example describes an excess storage scenario for projects in a namespace:

| Repository | Storage used | Excess storage | Quota  | Status               |
|------------|--------------|----------------|--------|----------------------|
| Red        | 10 GiB        | 0 GiB           | 10 GiB  | Read-only {{< icon name="lock" >}} |
| Blue       | 8 GiB         | 0 GiB           | 10 GiB  | Not read-only        |
| Green      | 10 GiB        | 0 GiB           | 10 GiB  | Read-only {{< icon name="lock" >}} |
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
- Excess storage usage is 20%: 10 GiB / 50 GiB × 100.
- Remaining purchased storage is 80%.

## Manage storage usage

To manage your storage, if you are a namespace Owner of a Free GitLab.com namespace,
you can purchase more storage for the namespace.

In the Premium and Ultimate tier, depending on your role, you can also
[reduce repository size](project/repository/repository_size.md#methods-to-reduce-repository-size).
To automate storage usage analysis and management, see [storage management automation](storage_management_automation.md).

In addition to managing your storage usage you can consider these options for increased consumables:

- If you are eligible, apply for a [community program subscription](../subscriptions/community_programs.md):
  - GitLab for Education
  - GitLab for Open Source
  - GitLab for Startups
- Consider a [GitLab Self-Managed subscription](../subscriptions/self_managed/_index.md), which does not have storage limits.
- [Talk to an expert](https://page.gitlab.com/usage_limits_help.html) for more information about your options.

## Purchase more storage

{{< details >}}

- Tier: Free

{{< /details >}}

{{< alert type="note" >}}

To exceed the free tier 10 GiB limit on your Free GitLab.com namespace, you can purchase more storage for your personal or group namespace.

{{< /alert >}}

Prerequisites:

- You must have the Owner role or be a billing account manager.
- The billing account must be linked to the subscription for the personal or group's namespace.

{{< alert type="note" >}}

Storage subscriptions **renew automatically each year**.
You can [disable automatic subscription renewal](../subscriptions/manage_subscription.md#turn-on-or-turn-off-automatic-subscription-renewal).

{{< /alert >}}

### For your personal namespace

1. Sign in to GitLab.com.
1. From either your personal homepage or the group's page, go to **Settings > Usage quotas**.
1. Select the **Storage** tab.
1. For each read-only project, total by how much its **Usage** exceeds the free quota and purchased
   storage. You must purchase the storage increment that exceeds this total.
1. Select **Buy storage**. You are taken to the Customers Portal.
1. In the **Subscription details** section, select the name of the user from the dropdown list.
1. Enter the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select the payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkboxes.
1. Select **Buy storage**.

The **Purchased storage available** total is incremented by the amount purchased. The read-only
state for all projects is removed, and their excess usage is deducted from the additional storage.

### For your group namespace

If you're using GitLab.com, you can purchase additional storage so your
pipelines aren't blocked after you have used all your storage from your
main quota. You can find pricing for additional storage on the
[GitLab Pricing page](https://about.gitlab.com/pricing/#storage).

To purchase additional storage for your group on GitLab.com:

{{< tabs >}}

{{< tab title="Group owner" >}}

1. Sign in to GitLab.com.
1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage quotas**.
1. Select the **Storage** tab.
1. Select **Buy storage**. You are taken to the Customers Portal.
1. In the **Subscription details** section, in the **Quantity** field, enter the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkbox.
1. Select **Buy storage**.

{{< /tab >}}

{{< tab title="Billing account manager" >}}

1. Go to [Customers Portal](https://customers.gitlab.com/customers/sign_in).
1. On the subscription card, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) and then **Buy more storage**.
1. In the **Subscription details** section, in the **Quantity** field enter, the desired quantity of storage packs.
1. In the **Customer information** section, verify your address.
1. In the **Billing information** section, select a payment method from the dropdown list.
1. Select the **Privacy Statement** and **Terms of Service** checkbox.
1. Select **Buy storage**.

{{< /tab >}}

{{< /tabs >}}

After your payment is processed, the extra storage is available for your group namespace.

To confirm the available storage, follow the first three steps listed previously.

The **Purchased storage available** total is incremented by the amount purchased. All locked
projects are unlocked and their excess usage is deducted from the additional storage.

## Fixed project limit

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

When a project's repository and LFS exceeds 500 GiB, the project is placed in a read-only state.
In this case, the owners of the group and top-level namespace receive in-app and email notifications warning them to manage their storage usage.
You can work with your account and support teams to manage your usage.
The 500 GiB fixed project limit is in place to ensure overall platform stability.

{{< alert type="note" >}}

These limits are fixed per project. Purchasing additional storage does not increase the maximum limit for
a single project. It only expands your overall available storage. For example, buying 1 TB of storage will
not cause one project to exceed its 500 GiB ceiling.

{{< /alert >}}

## Expired storage

Expired storage can exist on a subscription when storage is mistakenly not de-provisioned at the end of your subscription period.
If you experience an unexpected drop in purchased storage, expired storage could have been removed from your account.
For more information and solutions, contact support.

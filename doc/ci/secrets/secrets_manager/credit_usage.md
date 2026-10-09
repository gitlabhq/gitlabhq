---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Secrets Manager is billed, how it consumes GitLab Credits, and how to trial it.
title: GitLab Secrets Manager credit usage
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/10723) in GitLab 19.3 for GitLab.com
- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/17903) for GitLab Self-Managed in GitLab 19.5.

{{< /history >}}

GitLab Secrets Manager usage consumes [GitLab Credits](../../../subscriptions/gitlab_credits.md)
based on two meters:

- Secrets stored: number of secrets held in the Secrets Manager, measured per secret per month.
- Secret operations: fetching a secret (in pipelines, from Kubernetes clusters, or by API) is one operation.
  Secret updates and deletions don't count as operations.

## GitLab Credits consumption

GitLab Credits used for GitLab Secrets Manager are drawn from the [monthly commitment pool](../../../subscriptions/gitlab_credits.md#monthly-commitment-pool) and [on-demand credits](../../../subscriptions/gitlab_credits.md#on-demand-credits) available in the top-level group (namespace) or instance subscription.

- For GitLab.com, subgroups and projects consume the top-level group's credits.
- For GitLab Self-Managed, subgroups and projects consume the instance level credits.

> [!note]
> [Included credits](../../../subscriptions/gitlab_credits.md#included-credits)
> allocated to each user do not apply to GitLab Secrets Manager.

GitLab Credits usage caps do not limit Secrets Manager usage. Per-user caps do not apply because
usage is not attributed to individual users, and namespace spend caps do not block Secrets Manager consumption.

Credits are consumed for secrets storage and operations based on these rates:

| Type           | Rates                 | Credits | Details |
|----------------|-----------------------|---------|---------|
| Stored secrets | One secret, monthly | 1       | Credit consumption is prorated daily, based on how long a secret exists. For example, two secrets stored for half a month consumes one credit. |
| Secret reads   | 2,500 reads       | 1       | Secret read operations across all secrets. Includes retrieving secrets with a CI/CD job, the Secrets Manager API, or integrations (ESO, Terraform, OpenBao CLI). |

View and manage credit usage in the [GitLab Credits dashboard](../../../subscriptions/gitlab_credits_dashboard.md).

### In CI/CD jobs

Each secret successfully fetched in a CI/CD job counts as one read operation, even if the job later fails.
A job that references multiple secrets performs one read operation for each secret.
If you retry the job, the secrets are fetched again.

Secret operations do not consume credits if the read operation fails, including when:

- The referenced secret doesn't exist.
- The read fails due to a permission error.

### Examples

To help gauge the expected monthly consumption of secrets in different situations,
here are some examples:

- A small team with 25 secrets stored, 500 pipelines per month, and 5 secrets read per pipeline.
  - Storage: 25 secrets = 25 credits
  - Operations: 2,500 reads = 1 credit
  - Monthly total: 26 credits
- A multi-environment application with 120 secrets across development, staging, and production environments,
  2,000 pipelines per month, and 5 secrets read per pipeline.
  - Storage: 120 secrets = 120 credits
  - Operations: 10,000 reads = 4 credits
  - Monthly total: 124 credits
- Enterprise-level usage with 1,000 secrets stored, 50,000 pipelines per month,
  and 10 secrets read per pipeline.
  - Storage: 1,000 secrets = 1,000 credits
  - Operations: 500,000 reads = 200 credits
  - Monthly total: 1,200 credits

### Licensing on GitLab Self-Managed

Customers on GitLab Self-Managed can use GitLab Secrets Manager with their cloud license or offline license. Customers with an offline license must purchase the GitLab Secrets Manager add-on.

Customers with this add-on are billed under an Enterprise License Agreement (ELA) with a flat fee per customer.

Customers with a cloud license can use Secrets Manager without an add-on, and are billed based on usage.

To purchase GitLab Secrets Manager add-on (ELA), contact the GitLab Sales team.

## When your subscription ends

When the Premium or Ultimate subscription for your namespace is canceled or expires,
Secrets Manager enters a 14-day grace period that starts on the subscription end date.

During the grace period:

- Pipelines and service accounts can still perform secret read operations.
- You cannot create or update secrets, but you can still view details and delete secrets.

When the grace period ends, secret read operations are blocked. GitLab does not delete your secrets,
and you can still view details or delete existing secrets.

To restore full access, renew your subscription.

On GitLab Self-Managed:

- With an online cloud license, the same 14-day grace period applies.
  The grace period starts when the license or the Secrets Manager add-on ends.
- With an offline license, secret operations are blocked as soon as the license no longer includes
  GitLab Secrets Manager. Offline licenses have no grace period.
  GitLab does not delete your secrets, and you can still view details or delete existing secrets.

## End of beta

Beta usage of the GitLab Secrets Manager didn't consume GitLab Credits.

- The beta for GitLab.com ended September 21, 2026.
- The beta for GitLab Self-Managed ends when you upgrade your instance to GitLab 19.5 or later.

On GitLab.com, if you did not start a trial, GitLab Secrets Manager is disabled and your secrets are read-only.
You can view details or delete existing secrets.

To restore access, start a trial or [enable GitLab Secrets Manager with GitLab Credits](_index.md#enable-with-gitlab-credits).

## Start a trial

You can evaluate GitLab Secrets Manager with a free 30-day trial. The trial provides a pool of
500 [temporary evaluation credits](../../../subscriptions/gitlab_credits.md#temporary-evaluation-credits)
for stored secrets and secret operations.

The trial ends when either happens first:

- 30 days pass from activation.
- All temporary evaluation credits are consumed.

Temporary evaluation credits are shared across the namespace, not allocated per user.
They don't roll over and can't be used after expiring.

You can activate a trial only once for your subscription.
If your namespace has previously used a trial, it is not eligible to activate another one.

If you disable GitLab Secrets Manager during your trial, you can re-enable it at any time before the end of your trial period.

At the end of the trial:

- If you have [GitLab Credits available](../../../subscriptions/gitlab_credits.md) in your subscription,
  usage continues without interruption, drawing from the monthly commitment pool, then on-demand credits.
- If you do not have access to GitLab credits, Secrets Manager operations are blocked,
  so read operations and dependent pipelines fail. To restore access, you must [buy GitLab Credits](../../../subscriptions/gitlab_credits.md#buy-gitlab-credits).

### On GitLab.com

Prerequisites:

- You must have the Owner role for the top-level group.

To start a trial:

1. In the top bar, select **Search or go to**, and find your top-level group.
1. In the left sidebar, select **Secure** > **Secrets manager**.
1. Select **Start 30-day trial**.
1. In the confirmation dialog, select **Start 30-day trial**.

### On GitLab Self-Managed

An administrator starts the trial for the instance.
The trial credits are shared across all groups and projects in the instance.
Offline instances cannot start a trial.

Prerequisites:

- Administrator access.
- You must have a Premium or Ultimate subscription.
- Your instance must have an online cloud license that has not used a trial.

To start a trial:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Secrets Manager**.
1. Select **Start 30-day trial**.
1. In the confirmation dialog, select **Start 30-day trial**.

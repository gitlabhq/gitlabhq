---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Secrets Manager is billed, how it consumes GitLab Credits, and how to trial it.
title: GitLab Secrets Manager credit usage
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/10723) in GitLab 19.3 for GitLab.com

{{< /history >}}

GitLab Secrets Manager usage consumes [GitLab Credits](../../../subscriptions/gitlab_credits.md)
based on two meters:

- Secrets stored: number of secrets held in the Secrets Manager, measured per secret per month.
- Secret operations: fetching a secret (in pipelines, from Kubernetes clusters, or by API) is one operation.
  Secret updates and deletions don't count as operations.

## GitLab Credits consumption

GitLab Credits used for GitLab Secrets Manager are drawn from the [Monthly Commitment Pool](../../../subscriptions/gitlab_credits.md#monthly-commitment-pool)
and [On-Demand credits](../../../subscriptions/gitlab_credits.md#on-demand-credits)
available in the top-level group's (namespace's) subscription. Secrets Manager usage
across the group's projects and subgroups consumes the top-level group's credits.

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

## When your subscription ends

When the Premium or Ultimate subscription for your namespace is canceled or expires,
Secrets Manager enters a 14-day grace period that starts on the subscription end date.

During the grace period:

- Pipelines and service accounts can still perform secret read operations.
- You cannot create, update, or delete secrets.

When the grace period ends, secret operations are blocked. GitLab does not delete your secrets,
and you can still view them in the UI.

To restore full access, renew your subscription.

## End of beta

Beta usage of the GitLab Secrets Manager doesn't consume GitLab Credits. The beta for GitLab.com ends September 21, 2026.

Any time before the end of the beta, you can start a trial
and use temporary evaluation credits. At the end of the trial, you must ensure you have GitLab Credits available
in your subscription to avoid any service disruption.

If you do not start the trial, the GitLab Secrets Manager is disabled at the end of the beta.

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

Prerequisites:

- You must have the Owner role for the top-level group.

1. In the top bar, select **Search or go to**, and find your top-level group.
1. In the left sidebar, select **Secure** > **Secrets Manager**.
1. Select **Start 30-day trial**.

At the end of the trial:

- If you have [GitLab Credits available](../../../subscriptions/gitlab_credits.md) in your subscription,
  usage continues without interruption, drawing from the monthly commitment pool, then on-demand credits.
- If you do not have access to GitLab credits, Secrets Manager operations are blocked,
  so read operations and dependent pipelines fail. To restore access, you must [buy GitLab Credits](../../../subscriptions/gitlab_credits.md#buy-gitlab-credits).

---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand how GitLab Secrets Manager is billed, how it consumes GitLab Credits, and how to trial it.
title: GitLab Secrets Manager usage and billing
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/10723) in GitLab 19.3 for GitLab.com

{{< /history >}}

[GitLab Secrets Manager](_index.md) is billed with usage-based pricing in
[GitLab Credits](../../../subscriptions/gitlab_credits.md).

Billing is based on two meters:

- Secrets stored: number of secrets held in the Secrets Manager, measured per secret per month.
- Secret operations: fetching a secret (in pipelines, from Kubernetes clusters, or by API) is one operation.
  Secret updates and deletions don't count as operations.

## Usage and billing

Credits used for GitLab Secrets Manager are drawn from the Monthly Commitment Pool and On-Demand credits.
Billing applies to the top-level group, not to individual projects.
All Secrets Manager usage across projects and subgroups in a root namespace is consolidated for billing.

> [!note]
> Included credits allocated to each user do not apply to GitLab Secrets Manager.
> Secrets Manager usage is measured at the namespace level, not per user, so it draws only from
> the shared credit pools above.

GitLab Credits spend caps do not limit Secrets Manager usage. Per-user caps do not apply because
usage is not attributed to individual users, and namespace spend caps do not block Secrets Manager consumption.

To use GitLab Secrets Manager, your subscription must have accepted the usage billing terms for
[On-Demand credits](../../../subscriptions/gitlab_credits.md#on-demand-credits). Usage billing terms apply to the subscription,
not to Secrets Manager alone. If your subscription doesn't have a Monthly Commitment Pool,
you can accept the usage billing terms in [Customers Portal](../../../subscriptions/gitlab_credits.md#buy-gitlab-credits).

A Secrets Manager trial doesn't require usage billing terms because it draws from its own trial credits.
The requirement to accept usage billing terms applies only after the trial ends.

You can activate a trial only once for your subscription.
If your namespace has previously used a trial, it is not eligible to activate another one.

### Secrets stored

You are charged for each secret stored, prorated daily. Storage is billed daily, based on how long a secret exists. If you create a secret partway through the month, or delete it before the month ends, you are charged only for the days the secret existed.

| Meter         | Unit                  | Credits |
|---------------|-----------------------|---------|
| Secret stored | Per secret, per month | 1       |

### Secret operations

You are charged for requests or read operations against secrets.

| Operation | Billable | Description |
|-----------|----------|-------------|
| Read      | {{< yes >}}      | Retrieve a secret value from a CI/CD job, Secrets Manager API, or integrations (ESO, Terraform, OpenBao CLI) |
| Write     | {{< no >}}       | Create a secret or update its value |
| Delete    | {{< no >}}       | Delete a secret |

| Meter             | Unit                 | Credits |
|-------------------|----------------------|---------|
| Secret operations | Per 2,500 operations | 1       |

Each secret fetched in a CI/CD job is one read operation per job. A job referencing three secrets performs three reads.
A retried job performs the reads again.

### What does not consume credits

- Operations that fail authorization and return no secret value.
- Usage during Beta didn't consume credits. Once usage-based billing starts, secrets stored during Beta
  begin consuming storage credits, and reads begin consuming operation credits.
  Review stored secrets before billing starts and delete any no longer needed.

### Failed and partial operations

- A read that fails (secret doesn't exist, or caller lacks read permission) is not billed.
- A read that succeeds is billed even if the job later fails or is canceled.
- Storage is prorated daily; a secret created and deleted in the same month is billed only for the days it existed.

### Pricing examples

Example 1: Small team with 25 secrets stored, 500 pipelines/month, and 5 secrets read per pipeline.

- Storage: 25 secrets = 25 credits
- Operations: 2,500 reads = 1 credit
- Monthly total: 26 credits

Example 2: Multi-environment application with 120 secrets across dev/staging/production,
2,000 pipelines/month, and 5 secrets read per pipeline.

- Storage: 120 secrets = 120 credits
- Operations: 10,000 reads = 4 credits
- Monthly total: 124 credits

Example 3: Enterprise-level usage with 1,000 secrets stored, 50,000 pipelines/month,
and 10 secrets read per pipeline.

- Storage: 1,000 secrets = 1,000 credits
- Operations: 500,000 reads = 200 credits
- Monthly total: 1,200 credits

### Monitor your usage

View and manage credit usage in the [GitLab Credits dashboard](../../../subscriptions/gitlab_credits.md#gitlab-credits-dashboard).

### When your subscription ends

When the Premium or Ultimate subscription for your namespace is canceled or expires,
Secrets Manager enters a 14-day grace period that starts on the subscription end date.

During the grace period:

- Pipelines and service accounts can still perform secret read operations.
- You cannot create, update, or delete secrets.

When the grace period ends, secret operations are blocked. GitLab does not delete your secrets,
and you can still view them in the UI.

To restore full access, renew your subscription.

## Trial

You can evaluate GitLab Secrets Manager with a free 30-day trial before committing to usage-based billing.
The trial provides a pool of 500 [temporary evaluation credits](../../../subscriptions/gitlab_credits.md#temporary-evaluation-credits) for stored secrets and secret operations.

The trial ends when either happens first:

- 30 days pass from activation.
- All temporary evaluation credits are consumed.

At the end of the trial:

- If you have accepted the usage billing terms, usage continues without interruption, drawing from the Monthly Commitment Pool,
  then On-Demand credits.
- If you haven't accepted the usage billing terms, Secrets Manager operations are blocked. Reads and dependent pipelines fail.
  To restore access, you must accept the usage billing terms.
  Then, the namespace returns to an eligible state immediately.

Temporary evaluation credits are shared across the namespace, not allocated per user.
They don't roll over and can't be used after expiring.

### Start a trial

Prerequisites:

- You must have the Owner role for the top-level group.

1. In the top bar, select **Search or go to**, and find your top-level group.
1. In the left sidebar, select **Secure** > **Secrets Manager**.
1. Select **Start 30-day trial**.

If you don't accept the usage billing terms in the Customers Portal, Secrets Manager stops working at the end of the trial.
Secret reads fail, and any pipeline that uses those secrets fails with them.

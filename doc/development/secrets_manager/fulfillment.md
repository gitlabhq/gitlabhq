---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager fulfillment and entitlement
ignore_in_report: true
---

Entitlement decides what a namespace can do with Secrets Manager, based on its trial, paid add-on, or billing status.
Entitlement is separate from the license and enrollment gates described in [Availability gates](_index.md#availability-gates).
All three must allow an action.

For how entitlement combines with the other states, see [Fulfillment combinations](states_and_side_effects.md#fulfillment-combinations).

## Entitlement states

`SecretsManagement::Entitlement` is a value object with no database row and no state machine.
`SecretsManagement::Entitlement::Resolver` computes it on demand.

| State | Meaning |
|-------|---------|
| `trial_eligible` | The namespace can start a trial but has not. |
| `trial` | A trial is running. |
| `paid` | Billing is active, including on-demand billing after a trial ends. |
| `offline_paid` | An offline instance has an active Secrets Manager add-on purchase. |
| `blocked` | Billing blocks the namespace. A `blocked_reason` is always set. |
| `ineligible` | No entitlement. Also the result when a lookup fails and no fallback applies. |

The `blocked_reason` values are `trial_expired`, `credits_exhausted`, `on_demand_disabled`, `grace`, and `subscription_grace_period_expired`.
The `grace` reason covers the 14 days after a paid subscription ends.
On GitLab.com, the window starts at the subscription end date.
On GitLab Self-Managed with an online license, it starts at the later of the Secrets Manager add-on purchase end and the license end.
The `gracePeriodEndDate` field on the entitlement type returns the last day of the window. It is set only when the blocked reason is `grace`.

## Where entitlement comes from

Where entitlement comes from depends on the type of instance.

- GitLab.com and GitLab Self-Managed instances with an online cloud license. The resolver asks CustomersDot through `Gitlab::SubscriptionPortal::Client`. It asks per top-level group on GitLab.com, and per instance on GitLab Self-Managed. CustomersDot returns the trial state and whether the consumer is blocked.
- Offline GitLab Self-Managed instances. An active `AddOnPurchase` for the Secrets Manager add-on gives `offline_paid`. Anything else gives `blocked` with `subscription_grace_period_expired`, so offline instances have no grace window.
- GitLab Self-Managed trial licenses, and instances with no license. These resolve to `ineligible`.

## What each state allows

| State | Initialize and provision | Read in UI and GraphQL | Read in CI and through the API | Create and update | Delete a secret | Permissions and deprovision |
|-------|--------------------------|------------------------|--------------------------------|-------------------|-----------------|-----------------------------|
| `trial`, `paid`, `offline_paid` | Allowed | Allowed | Allowed | Allowed | Allowed | Allowed |
| `blocked` with `grace` | Blocked | Allowed | Allowed | Blocked | Allowed | Blocked |
| `blocked` with any other reason | Blocked | Allowed | Blocked | Blocked | Allowed | Blocked |
| `trial_eligible` | Blocked | Top-level group only[^beta-cohort] | Blocked | Blocked | Top-level group only[^beta-cohort] | Blocked |
| `ineligible` | Blocked | Blocked | Blocked | Blocked | Blocked | Blocked |

[^beta-cohort]: Subgroups and projects are hidden, except for namespaces enrolled in the former beta program.

A `blocked` namespace is in loose read-only mode: reads and deletes still work, and writes do not.
Entitlement blocks deletes only when it also blocks reads.
Strict read-only is different.
It means the database itself is read-only, for example on a Geo secondary or in maintenance mode, and nothing is written.

The checks live in these places:

- Rails policies in `EE::ProjectPolicy` and `EE::GroupPolicy`. The rule that blocks writes leaves delete out on purpose.
- `SecretsManagement::EntitlementGate#validate_entitlement`, called by the initialize and provision services.
- The `EnforcesWriteEntitlement` concern on GraphQL mutations. Secret delete mutations do not include it.
- CI job pickup in `EE::Ci::RegisterJobService` and `EE::Ci::BuildRunnerPresenter`.

## Trials and add-ons

On GitLab.com, the `SecretsManagerStartTrial` mutation starts a trial in CustomersDot.
Before it starts one, it asks CustomersDot for a fresh answer, past every cache.
It refuses unless the group is `trial_eligible`. A group with a running trial gets a `trial_already_active` error, and any other state gets an `ineligible` error.
The `SecretsManagerEnableAddOn` mutation turns on paid billing without a trial.
On GitLab.com, both also provision the top-level group's secrets manager when the user has the `provision_secrets_manager` ability.
If provisioning fails after a trial starts, the trial stays active, and the error is returned next to the entitlement.
Both have instance-level versions for GitLab Self-Managed instances.
These mutations clear the entitlement caches, so the new state shows up right away.

The `SecretsManagerRefreshEntitlement` mutation, and its instance version, asks CustomersDot again and skips every cache.
It is for users who just changed billing consent in the Customers Portal.
It needs the `enable_secrets_manager_add_on` ability and is limited to 10 calls per user per minute.
A failed refresh returns an error and keeps the cached answers and the last-known-good answer.
The instance version returns an error on an offline license.

When a trial ends, the namespace becomes `blocked` with `trial_expired`, or `paid` if on-demand billing is on.
Nothing is deprovisioned or deleted.
An `active` secrets manager stays `active`, and its secrets are kept in loose read-only mode.

## Caching and outages

Entitlement answers are cached at several layers, so a billing change does not always show up right away.

- Per request, the resolver caches its answer in `SafeRequestStore`.
- CI job pickup also caches the entitlement in `Rails.cache` for one minute. The cache key includes a digest of the `Entitlement` field list, because `Entitlement.new` rejects unknown keys. If you add a field to `Entitlement`, the key changes on its own, so old and new nodes do not read each other's entries during a rolling deploy.
- The CustomersDot client caches each response in `Rails.cache` for the response `Cache-Control` max-age, or 120 seconds without one. Errors are never cached.
- A last-known-good store keeps the most recent CustomersDot answers in Redis for 24 hours.

When CustomersDot is unavailable, the resolver replays the last-known-good answer, but only if that answer allowed direct reads.
Otherwise the lookup fails closed to `ineligible`, which blocks UI reads and CI jobs.
The last-known-good fallback has an ops feature flag as a kill switch.

A change made in CustomersDot outside GitLab, such as a renewal, does not clear any cache.
The old answer can last until the CustomersDot cache expires, unless a user runs the refresh entitlement mutation.
A refresh replaces the cached answer only when CustomersDot answers, and it never replays the last-known-good answer.

## Beta program

The beta program has ended.
Namespaces enrolled in the beta, marked by `beta` on `NamespaceEnrollment` or by instance enrollment on GitLab Self-Managed, get the same entitlement as everyone else.
The only difference is that a beta namespace in `trial_eligible` can still see and delete secrets on its subgroups and projects.

## Billing events

Secrets Manager emits two usage events:

- `secrets_stored`. A daily cron counts stored secrets per root namespace, from `NamespaceSecretCount`, and emits one event per namespace with a non-zero count.
- `secrets_read`. One event per successful secret read, taken from the OpenBao audit log.

Entitlement does not block either event.
Both carry the entitlement state and blocked reason as metadata, and CustomersDot decides how to rate them.
Opted-out namespaces on GitLab.com and unenrolled GitLab Self-Managed instances do not emit `secrets_stored`.

Secret counts are kept up to date by `ReconcileNamespaceSecretCountWorker`.
It runs after every secret create and delete, after deprovision, and from a daily cron.
It counts secrets in OpenBao and removes the count row when the secrets manager is missing or not `active`.

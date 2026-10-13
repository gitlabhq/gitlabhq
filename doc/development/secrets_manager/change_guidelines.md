---
stage: Security Platform
group: Secrets Manager Application
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Secrets Manager change guidelines
ignore_in_report: true
---

Use these guidelines when you write or review a change to Secrets Manager code.
Secrets Manager has several kinds of state that can be true at the same time, and each state change has required side effects.
A change can look correct on its own and still break when another state is true.
For how the states combine, see [Secrets Manager states and side effects](states_and_side_effects.md).

## Keep the documentation current

The pages under `doc/development/secrets_manager/` describe how the code works today.
Reviewers rely on them, and so does the automated reviewer that uses the Secrets Manager principle.

- If your change alters behavior that a page describes, update that page in the same merge request.
- If you find a page that was already out of date, fix it in the same merge request or in a follow-up.

## Pages for each area

Depending on which files a change touches, these pages have more detail:

| Changed files | Page |
|---------------|------|
| Paths or code about `entitlement`, `trial`, `add_on`, `billable`, `subscription_portal`, or `secret_count` | [Secrets Manager fulfillment and entitlement](fulfillment.md) |
| Paths about `enrollment` or `availability` | [Secrets Manager enrollment](enrollment.md) |
| `ee/app/services/secrets_management/` or `ee/app/services/concerns/secrets_management/` | [Secrets Manager services](services.md) |
| `ee/app/graphql/`, or `graphql/` under `ee/app/assets/javascripts/ci/secrets/` | [Secrets Manager GraphQL API](graphql.md) |
| `ee/lib/secrets_management/` for the client, JWT, access control list (ACL), or Common Expression Language (CEL) code, or `*_helper.rb` under `ee/app/models/secrets_management/` | [Secrets Manager OpenBao client and authentication](openbao_client.md) |
| `ee/app/workers/secrets_management/`, `ee/app/policies/`, or `ee/lib/api/internal/` | [Secrets Manager workers and policies](workers_and_policies.md) |
| `register_job_service.rb`, `build_runner_presenter.rb`, `secrets_manager_client.rb`, `ci_policies/`, list or count services, or cron workers | [Secrets Manager performance](performance.md) |
| Other files under `ee/app/models/secrets_management/` | [Secrets Manager architecture](architecture.md) |
| Only specs under `ee/spec/` | [Secrets Manager testing](testing.md) |
| Only files under `ee/app/assets/javascripts/ci/secrets/` | [Secrets Manager frontend development](frontend.md) |

## Checklist for changes

Answer these questions for each change:

1. Does cleanup code read the live project or group? The parent can already be gone, so use the IDs stored on the secrets manager row or the task.
1. Does a new write path take the per-entity lease, and fail immediately instead of proceeding without it?
1. If the change fixes the project side, does the group side need the same fix, or the other way around? Check [Project and group differences](states_and_side_effects.md#project-and-group-differences) first.
1. Do create, read, update, and delete (CRUD) operations still reject a secrets manager that is not `active`, including one with a pending deprovision task?
1. Could the unique task index make a new task insert do nothing? Only one task per project or group can exist at a time.
1. Could a bulk operation race with a per-record operation on the same entity? Confirm workers only run for rows that were actually inserted.
1. Does the change handle secrets managers that project or group transfer skips because they are still provisioning?
1. Does a namespace teardown change still tolerate the two harmless errors listed in [Side effects on state transitions](states_and_side_effects.md#side-effects-on-state-transitions)?
1. Does the change add an auditable action without a matching audit event?
1. Does the change update a Rails policy without the matching OpenBao ACL or CEL logic, or the other way around? For more information, see [Two authorization layers](_index.md#two-authorization-layers).
1. Does the change rely on `metadata_cas` correctly, or could it overwrite a concurrent update?
1. Does a new write path check entitlement in the same places its peers do?
1. Does new code include the same guards as its closest existing peer, such as concerns, policy rules, active namespace checks, and feature checks? A guard the peer has and the new code lacks is a likely bug, unless the change explains why.
1. Does the change assume entitlement stays the same during a multi-step operation, such as provisioning or a running pipeline?
1. Does the deprovision worker or a cleanup cron call an entitlement check that could block it?
1. Does the change handle loose read-only, where reads and deletes work but writes do not, separately from strict read-only?

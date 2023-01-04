---
status: ready
creation-date: "2022-10-27"
authors: [ "@pedropombeiro", "@tmaczukin" ]
coach: "@ayufan"
approvers: [ "@erushton" ]
owning-stage: "~devops::verify"
participating-stages: []
---

# Next GitLab Runner Token Architecture

## Summary

GitLab Runner is a core component of GitLab CI/CD that runs
CI/CD jobs in a reliable and concurrent environment. Ever since the beginnings
of the service as a Ruby program, runners are registered in a GitLab instance with
a registration token - a randomly generated string of text. The registration token is unique for its given scope
(instance, group, or project). The registration token proves that the party that registers the runner has
administrative access to the instance, group, or project to which the runner is registered.

This approach has worked well in the initial years, but some major known issues started to
become apparent as the target audience grew:

| Problem                                     | Symptoms                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
|---------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Single token per scope                      | - The registration token is shared by multiple runners: <br/>- Single tokens lower the value of auditing and make traceability almost impossible; <br/>- Copied in many places for [self-registration of runners](https://docs.gitlab.com/runner/install/kubernetes.html#required-configuration); <br/>- Reports of users storing tokens in unsecured locations; <br/>- Makes rotation of tokens costly. <br/>- In the case of a security event affecting the whole instance, rotating tokens requires users to update a table of projects/namespaces, which takes a significant amount of time. |
| No provision for automatic expiration       | Requires manual intervention to change token. Addressed in [#30942](https://gitlab.com/gitlab-org/gitlab/-/issues/30942).                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| No permissions model                        | Used to register a runner for protected branches, and for any tags. In this case, the registration token has permission to do everything. Effectively, someone taking a possession of registration token could steal secrets or source code.                                                                                                                                                                                                                                                                                                                                                       |
| No traceability                             | Given that the token is not created by a user, and is accessible to all administrators, there is no possibility to know the source of a leaked token.                                                                                                                                                                                                                                                                                                                                                                                                                  |
| No historical records                       | When reset, the previous value of the registration token is not stored so there is no historical data to enable deeper auditing and inspection.                                                                                                                                                                                                                                                                                                                                                                                                                        |
| Token stored in project/namespace model     | Inadvertent disclosure of token is possible.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| Too many registered runners                 | It is too straightforward to register a new runner using a well-known registration token.                                                                                                                                                                                                                                                                                                                                                                                                                                                                              |

In light of these issues, it is important that we redesign the way in which we connect runners to the GitLab instance so that we can guarantee traceability, security, and performance.

We call this new mechanism the "next GitLab Runner Token architecture".

## Proposal

The proposal addresses the issues of a _single token per scope_ and _token storage_
by eliminating the need for a registration token. Runner creation happens
in the GitLab Runners settings page for the given scope, in the context of the logged-in user,
which provides traceability. The page provides instructions to configure the newly-created
runner in supported environments using the existing `gitlab-runner register` command.

The remaining concerns become non-issues due to the elimination of the registration token.

### Using the authentication token in place of the registration token

<!-- vale gitlab.Spelling = NO -->
In this proposal, runners created in the GitLab UI are assigned authentication tokens prefixed with
`glrt-` (**G**it**L**ab **R**unner **T**oken).
<!-- vale gitlab.Spelling = YES -->
The prefix allows the existing `register` command to use the authentication token _in lieu_
of the current registration token (`--registration-token`), requiring minimal adjustments in
existing workflows.
The authentication token is shown to the user only once - after completing the creation flow - to
discourage unintended reuse.

Given that the runner is pre-created through the GitLab UI, the `register` command fails if
provided with arguments that are exposed in the runner creation form.
Some examples are `--tag-list`, `--run-untagged`, `--locked`, or `--access-level` as these are
sensitive parameters that should be decided at creation time by an administrator/owner.
The runner configuration is generated through the existing `register` command, which can behave in
two different ways depending on whether it is supplied a registration token or an authentication
token in the `--registration-token` argument:

| Token type | Behavior |
| ---------- | -------- |
| Registration token | Leverages the `POST /api/v4/runners` REST endpoint to create a new runner, creating a new entry in `config.toml`. |
| Authentication token | Leverages the `POST /api/v4/runners/verify` REST endpoint to ensure the validity of the authentication token. Creates an entry in `config.toml` file and a `system_id` value in a sidecar file if missing (`.runner_system_id`). |

### Transition period

During a transition period, legacy tokens ("registration tokens") continue to be shown on the
GitLab Runners settings page and to be accepted by the `gitlab-runner register` command.
The legacy workflow is nevertheless discouraged in the UI.
Users are steered towards the new flow consisting of creating the runner in the UI and using the
resulting authentication token with the `gitlab-runner register` command as they do today.
This approach reduces disruption to users responsible for deploying runners.

### Reusing the runner authentication token across many machines

In the existing model, a new runner is created whenever a new worker is required. This
has led to many situations where runners are left behind and become stale.

In the proposed model, a `ci_runners` table entry describes a configuration that the user can reuse
across multiple machines.
A unique system identifier is [generated automatically](#generating-a-system_id-value) whenever the
runner application starts up or the configuration is saved.
This allows differentiating the context in which the runner is being used.

The `system_id` value complements the short runner token that is currently used to identify a
runner in command line output, CI job logs, and GitLab UI.

Given that the creation of runners involves user interaction, it should be possible
to eventually lower the per-plan limit of CI runners that can be registered per scope.

#### Generating a `system_id` value

We ensure that a unique system identifier is assigned at all times to a `gitlab-runner`
installation.
The ID is derived from an existing machine identifier such as `/etc/machine-id` (on Linux) and
hashed for privacy, in which case it is prefixed with `s_`.
If an ID is not available, a random string is used instead, in which case it is prefixed with `r_`.

This unique ID identifies the `gitlab-runner` process and is sent
on `POST /api/v4/jobs` requests for all runners in the `config.toml` file.

The ID is generated and saved both at `gitlab-runner` startup and whenever the configuration is
saved to disk.
Instead of saving the ID at the root of `config.toml` though, we save it to a new file that lives
next to it - `.runner_system_id`. The goal for this new file is to make it less likely that IDs
get reused due to manual copying of the `config.toml` file

```plain
s_cpwhDr7zFz4xBJujFeEM
```

### Runner identification in CI jobs

For users to identify the machine where the job was executed, the unique identifier needs to be
visible in CI job contexts.
As a first iteration, GitLab Runner will include the unique system identifier in the build logs,
wherever it publishes the short token SHA.

Given that the runner can potentially be reused with different unique system identifiers,
we should store the unique system ID in the database.
This ensures the unique system ID maps to a GitLab Runner's `system_id` value with the runner token.
A new `ci_runner_machines` table holds information about each unique runner machine,
with information regarding when the runner last connected, and what type of runner it was.

In the long term, the relevant fields are to be moved from the `ci_runners` into
`ci_runner_machines`.
Until the removal milestone though, they should be kept in the `ci_runners` as a fallback when a
matching `ci_runner_machines` record does not exist.
An expected scenario is the case when the table is created but the runner hasn't pinged the GitLab
instance (for example if the runner is offline).

In addition, we should add the following columns to `ci_runners`:

- a `creator_id` column to keep track of who created a runner;
- a `registration_type` enum column to `ci_runners` to signal whether a runner has been created
  using the legacy `register` method, or the new UI-based method.
  Possible values are `:registration_token` and `:authenticated_user`.
  This allows the stale runner cleanup service to determine which runners to clean up, and allows
  future uses that may not be apparent.

```sql
CREATE TABLE ci_runners (
  ...
  creator_id bigint
  registration_type int8
)
```

The `ci_builds_metadata` table shall reference `ci_runner_machines`.
We might consider a more efficient way to store `contacted_at` than updating the existing record.

```sql
CREATE TABLE ci_builds_metadata (
    ...
    runner_machine_id bigint NOT NULL
);

CREATE TABLE ci_runner_machines (
    id bigint NOT NULL,
    machine_xid character varying UNIQUE NOT NULL,
    contacted_at timestamp without time zone,
    version character varying,
    revision character varying,
    platform character varying,
    architecture character varying,
    ip_address character varying,
    executor_type smallint,
);
```

## Advantages

- Easier for users to wrap their minds around the concept: instead of two types of tokens,
  there is a single type of token - the per-runner authentication token. Having two types of tokens
  frequently results in misunderstandings when discussing issues;
- Runners can always be traced back to the user who created it, using the audit log;
- The claims of a CI runner are known at creation time, and cannot be changed from the runner
  (for example, changing the `access_level`/`protected` flag). Authenticated users
  may however still edit these settings through the GitLab UI;
- Easier cleanup of stale runners, which doesn't touch the `ci_runner` table.

## Details

In the proposed approach, we create a distinct way to configure runners that is usable
alongside the current registration token method during a transition period. The idea is
to avoid having the Runner make API calls that allow it to leverage a single "god-like"
token to register new runners.

The new workflow looks as follows:

  1. The user opens the Runners settings page (instance, group, or project level);
  1. The user fills in the details regarding the new desired runner, namely description,
  tags, protected, locked, etc.;
  1. The user clicks `Create`. That results in the following:

      1. Creates a new runner in the `ci_runners` table (and corresponding `glrt-` prefixed authentication token);
      1. Presents the user with instructions on how to configure this new runner on a machine,
         with possibilities for different supported deployment scenarios (e.g. shell, `docker-compose`, Helm chart, etc.)
         This information contains a token which is available to the user only once, and the UI
         makes it clear to the user that the value shall not be shown again, as registering the same runner multiple times
         is discouraged (though not impossible).

  1. The user copies and pastes the instructions for the intended deployment scenario (a `register` command), leading to the following actions:

      1. Upon executing the new `gitlab-runner register` command in the instructions, `gitlab-runner` performs
      a call to the `POST /api/v4/runners/verify` with the given runner token;
      1. If the `POST /api/v4/runners/verify` GitLab endpoint validates the token, the `config.toml`
      file is populated with the configuration;
      1. Whenever a runner pings for a job, the respective `ci_runner_machines` record is
         ["upserted"](https://en.wiktionary.org/wiki/upsert) with the latest information about the
         runner (with Redis cache in front of it like we do for Runner heartbeats).

As part of the transition period, we provide admins and top-level group owners with an
instance/group-level setting (`allow_runner_registration_token`) to disable the legacy registration
token functionality and enforce using only the new workflow.
Any attempt by a `gitlab-runner register` command to hit the `POST /api/v4/runners` endpoint
to register a new runner with a registration token results in a `HTTP 410 Gone` status code.

The instance setting is inherited by the groups. This means that if the legacy registration method
is disabled at the instance method, the descendant groups/projects mandatorily prevents the legacy
registration method.

The registration token workflow is to be deprecated (with a deprecation notice printed by the `gitlab-runner register` command)
and removed at a future major release after the concept is proven stable and customers have migrated to the new workflow.

### Handling of legacy runners

Legacy versions of GitLab Runner do not send the unique system identifier in its requests, and we
will not change logic in Workhorse to handle unique system IDs. This can be improved upon in the
future after the legacy registration system is removed, and runners have been upgraded to newer
versions.

Job pings from such legacy runners results in a `ci_runner_machines` record containing a
`<legacy>` `machine_xid` field value.

Not using the unique system ID means that all connected runners with the same token are
notified, instead of just the runner matching the exact system identifier. While not ideal, this is
not an issue per-se.

### `ci_runner_machines` record lifetime

New records are created when the runner pings the GitLab instance for new jobs, if a record matching
the `token`+`system_id` does not already exist.

Due to the time-decaying nature of the `ci_runner_machines` records, they are automatically
cleaned after 7 days after the last contact from the respective runner.

### Required adaptations

#### Migration to `ci_runner_machines` table

When details from `ci_runner_machines` are needed, we need to fall back to the existing fields in
`ci_runner` if a match is not found in `ci_runner_machines`.

#### REST API

API endpoints receiving runner tokens should be changed to also take an optional
`system_id` parameter, sent alongside with the runner token (most often as a JSON parameter on the
request body).

#### GraphQL `CiRunner` type

The [`CiRunner` type](../../../api/graphql/reference/index.md#cirunner) closely reflects the
`ci_runners` model. This means that machine information such as `ipAddress`, `architectureName`,
and `executorName` among others are no longer singular values in the proposed approach.
We can live with that fact for the time being and start returning lists of unique values, separated
by commas.
The respective `CiRunner` fields must return the values for the `ci_runner_machines` entries
(falling back to `ci_runner` record if non-existent).

#### Stale runner cleanup

The functionality to
[clean up stale runners](../../../ci/runners/configure_runners.md#clean-up-stale-runners) needs
to be adapted to clean up `ci_runner_machines` records instead of `ci_runners` records.

At some point after the removal of the registration token support, we'll want to create a background
migration to clean up stale runners that have been created with a registration token (leveraging the
enum column created in the `ci_runners` table.

### Runner creation through API

Automated runner creation may be allowed, although always through authenticated API calls -
using PAT tokens for example - such that every runner is associated with an owner.

## Implementation plan

### Stage 1 - Deprecations

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Rails app | `15.6` | Deprecate `POST /api/v4/runners` endpoint for `17.0`. This hinges on a [proposal](https://gitlab.com/gitlab-org/gitlab/-/issues/373774) to allow deprecating REST API endpoints for security reasons. |
| GitLab Runner    | `15.6` | Add deprecation notice for `register` command for `17.0`. |
| GitLab Runner Helm Chart | `15.6` | Add deprecation notice for `runnerRegistrationToken` command for `17.0`. |
| GitLab Runner Operator | `15.6` | Add deprecation notice for `runner-registration-token` command for `17.0`. |
| GitLab Runner / GitLab Rails app | `15.7` | Add deprecation notice for registration token reset for `17.0`. |

### Stage 2 - Prepare `gitlab-runner` for `system_id`

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Runner    | `15.x` | Ensure a sidecar TOML file exists with a `system_id` value.<br/>Log new system ID values with `INFO` level as they get assigned. |
| GitLab Runner    | `15.x` | Log unique system ID in the build logs. |
| GitLab Runner    | `15.x` | Label Prometheus metrics with unique system ID. |
| GitLab Runner    | `15.x` | Prepare `register` command to fail if runner server-side configuration options are passed together with a new `glrt-` token. |

### Stage 3 - Database changes

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Rails app | | Create database migration to add columns to `ci_runners` table. |
| GitLab Rails app | | Create database migration to add `ci_runner_machines` table. |
| GitLab Rails app | | Create database migration to add `ci_runner_machines.id` foreign key to `ci_builds_metadata` table. |
| GitLab Rails app | | Create database migrations to add `allow_runner_registration_token` setting to `application_settings` and `namespace_settings` tables (default: `true`). |
| GitLab Rails app | | Use runner token + `system_id` JSON parameters in `POST /jobs/request` request in the [heartbeat request](https://gitlab.com/gitlab-org/gitlab/blob/c73c96a8ffd515295842d72a3635a8ae873d688c/lib/api/ci/helpers/runner.rb#L14-20) to update the `ci_runner_machines` cache/table. |
| GitLab Runner    | | Start sending `system_id` value in `POST /jobs/request` request and other follow-up requests that require identifying the unique system. |
| GitLab Rails app | | Create service similar to `StaleGroupRunnersPruneCronWorker` service to clean up `ci_runner_machines` records instead of `ci_runners` records.<br/>Existing service continues to exist but focuses only on legacy runners. |

### Stage 4 - New UI

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Runner    | | Implement new GraphQL user-authenticated API to create a new runner. |
| GitLab Runner    | | [Add prefix to newly generated runner authentication tokens](https://gitlab.com/gitlab-org/gitlab/-/issues/383198). |
| GitLab Rails app | | Implement UI to create new runner. |
| GitLab Rails app | | GraphQL changes to `CiRunner` type. |
| GitLab Rails app | | UI changes to runner details view (listing of platform, architecture, IP address, etc.) (?) |

### Stage 5 - Optional disabling of registration token

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Rails app | | Add UI to allow disabling use of registration tokens at project or group level. |
| GitLab Rails app | `16.0` | Introduce `:disable_runner_registration_tokens` feature flag (enabled by default) to control whether use of registration tokens is allowed. |
| GitLab Rails app | | Make [`POST /api/v4/runners` endpoint](../../../api/runners.md#register-a-new-runner) permanently return `HTTP 410 Gone` if either `allow_runner_registration_token` setting or `:disable_runner_registration_tokens` feature flag disables registration tokens.<br/>A future v5 version of the API should return `HTTP 404 Not Found`. |
| GitLab Rails app | | Start refusing job requests that don't include a unique ID, if either `allow_runner_registration_token` setting or `:disable_runner_registration_tokens` feature flag disables registration tokens. |
| GitLab Rails app | | Hide legacy UI showing registration with a registration token, if `:disable_runner_registration_tokens` feature flag disables registration tokens. |

### Stage 6 - Removals

| Component        | Milestone | Changes |
|------------------|----------:|---------|
| GitLab Rails app | `17.0` | Remove legacy UI showing registration with a registration token. |
| GitLab Runner    | `17.0` | Remove runner model arguments from `register` command (for example `--run-untagged`, `--tag-list`, etc.) |
| GitLab Rails app | `17.0` | Create database migrations to drop `allow_runner_registration_token` setting columns from `application_settings` and `namespace_settings` tables. |
| GitLab Rails app | `17.0` | Create database migrations to drop:<br/>- `runners_registration_token`/`runners_registration_token_encrypted` columns from `application_settings`;<br/>- `runners_token`/`runners_token_encrypted` from `namespaces` table;<br/>- `runners_token`/`runners_token_encrypted` from `projects` table. |
| GitLab Rails app | `17.0` | Remove `:disable_runner_registration_tokens` feature flag. |

## Status

Status: RFC.

## Who

Proposal:

<!-- vale gitlab.Spelling = NO -->

| Role                         | Who
|------------------------------|--------------------------------------------------|
| Authors                      | Kamil Trzciński, Tomasz Maczukin, Pedro Pombeiro |
| Architecture Evolution Coach | Kamil Trzciński                                  |
| Engineering Leader           | Elliot Rushton, Cheryl Li                        |
| Product Manager              | Darren Eastman, Jackie Porter                    |
| Domain Expert / Runner       | Tomasz Maczukin                                  |

DRIs:

| Role                         | Who                             |
|------------------------------|---------------------------------|
| Leadership                   | Elliot Rushton                  |
| Product                      | Darren Eastman                  |
| Engineering                  | Tomasz Maczukin, Pedro Pombeiro |

Domain experts:

| Area                         | Who             |
|------------------------------|-----------------|
| Domain Expert / Runner       | Tomasz Maczukin |

<!-- vale gitlab.Spelling = YES -->

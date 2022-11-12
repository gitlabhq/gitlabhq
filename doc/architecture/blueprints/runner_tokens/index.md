---
stage: Verify
group: Runner
comments: false
description: 'Next Runner Token Architecture'
---

# Next GitLab Runner Token Architecture

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
As with all projects, the items mentioned on this page are subject to change or delay.
The development, release, and timing of any products, features, or functionality remain at the
sole discretion of GitLab Inc.

## Summary

GitLab Runner is a core component of GitLab CI/CD that runs
CI/CD jobs in a reliable and concurrent environment. Ever since the beginnings
of the service as a Ruby program, runners are registered in a GitLab instance with
a registration token - a randomly generated string of text. The registration token is unique for its given scope
(instance, group, or project). The registration token proves that the party that registers the runner has
administrator access to the instance, group, or project to which the runner is registered.

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
in the GitLab Runners settings page for the given scope, in the context of the logged-in user
, which provides traceability. The page provides instructions to configure the newly-created
runner in supported environments.

The runner configuration will be generated through a new `deploy` command, which will leverage
the `/runners/verify` REST endpoint to ensure the validity of the authentication token.
The remaining concerns become non-issues due to the elimination of the registration token.

The configuration can be applied across many machines by reusing the same instructions.
A unique system identifier will be generated automatically if a value is missing from
the runner entry in the `config.toml` file. This allows differentiating systems sharing the same
runner token (for example, in auto-scaling scenarios), and is crucial for the proper functioning of our
long-polling mechanism when the same authentication token is shared across two or more runner managers.

Given that the creation of runners involves user interaction, it should be possible
to eventually lower the per-plan limit of CI runners that can be registered per scope.

### Auto-scaling scenarios (for example Helm chart)

In the existing model, a new runner is created whenever a new worker is required. This
has led to many situations where runners are left behind and become stale.

In the proposed model, a `ci_runners` table entry describes a configuration,
which the runner could reuse across multiple machines. This allows differentiating the context in
which the runner is being used. In situations where we must differentiate between runners
that reuse the same configuration, we can use the unique system identifier to track all
unique "runners" that are executed in context of a single `ci_runners` model. This unique
system identifier would be present in the Runner's `config.toml` configuration file and
initially set when generating the new `[[runners]]` configuration by means of the `deploy` command.
Legacy files that miss values for unique system identifiers will get rewritten automatically with new values.

### Runner identification in CI jobs

For users to identify the machine where the job was executed, the unique identifier will need to be visible in CI job contexts.
As a first iteration, GitLab Runner will include the unique system identifier in the build logs,
wherever it publishes the short token SHA.

Given that the runner will potentially be reused with different unique system identifiers,
we can store the unique system ID. This ensures the unique system ID maps to a GitLab Runner's `config.toml` entry with
the runner token. The `ci_runner_machines` would hold information about each unique runner machine,
with information when runner last connected, and what type of runner it was. The relevant fields
will be moved from the `ci_runners`.
The `ci_builds_runner_session` (or `ci_builds` or `ci_builds_metadata`) will reference
`ci_runner_machines`.
We might consider a more efficient way to store `contacted_at` than updating the existing record.

```sql
CREATE TABLE ci_builds_runner_session (
    ...
    runner_machine_id bigint NOT NULL
);

CREATE TABLE ci_runner_machines (
    id integer NOT NULL,
    machine_id character varying UNIQUE NOT NULL,
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
  may however still edit these settings through the GitLab UI.

## Details

In the proposed approach, we create a distinct way to configure runners that is usable
alongside the current registration token method during a transition period. The idea is
to avoid having the Runner make API calls that allow it to leverage a single "god-like"
token to register new runners.

The new workflow looks as follows:

  1. The user opens the Runners settings page;
  1. The user fills in the details regarding the new desired runner, namely description,
  tags, protected, locked, etc.;
  1. The user clicks `Create`. That results in the following:

      1. Creates a new runner in the `ci_runners` table (and corresponding authentication token);
      1. Presents the user with instructions on how to configure this new runner on a machine,
         with possibilities for different supported deployment scenarios (e.g. shell, `docker-compose`, Helm chart, etc.)
         This information contains a token which will only be available to the user once, and the UI
         will make it clear to the user that the value will not be shown again, as registering the same runner multiple times
         is discouraged (though not impossible).

  1. The user copies and pastes the instructions for the intended deployment scenario (a `deploy` command), leading to the following actions:

      1. Upon executing the new `gitlab-runner deploy` command in the instructions, `gitlab-runner` will perform
      a call to the `POST /runners/verify` with the given runner token;
      1. If the `POST /runners/verify` GitLab endpoint validates the token, the `config.toml` file will be populated with the configuration.

     The `gitlab-runner deploy` will also accept executor-specific arguments
     currently present in the `register` command.

As part of the transition period, we will provide admins and top-level group owners with a instance/group-level setting to disable
the legacy registration token functionality and enforce using only the new workflow.
Any attempt by a `gitlab-runner register` command to hit the `POST /runners` endpoint to register a new runner
will result in a `HTTP 410 - Gone` status code. The instance setting is inherited by the groups
, which means that if the legacy registration method is disabled at the instance method, the descendant groups/projects will also mandatorily
prevent the legacy registration method.

The registration token workflow is to be deprecated (with a deprecation notice printed by the `gitlab-runner register` command)
and removed at a future major release after the concept is proven stable and customers have migrated to the new workflow.

### Handling of legacy runners

Legacy versions of GitLab Runner will not send the unique system identifier in its requests, and we
will not change logic in Workhorse to handle unique system IDs. This can be improved upon in the
future once the legacy registration system is removed, and runners have been upgraded to newer
versions.

Not using the unique system ID means that all connected runners with the same token will be
notified, instead of just the runner matching the exact system identifier. While not ideal, this is
not an issue per-se.

### Helm chart

The `runnerRegistrationToken` entry in the [`values.yaml` file](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/a70bc29a903b79d5675bb0c45d981adf8b7a8659/values.yaml#L52)
will be retired. The `runnerRegistrationToken` entry will be replaced by the existing `runnerToken` value, which will be passed
to the new `gitlab-runner deploy` command in [`configmap.yaml`](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/blob/a70bc29a903b79d5675bb0c45d981adf8b7a8659/templates/configmap.yaml#L116).

### Runner creation through API

Automated runner creation may be allowed, although always through authenticated API calls -
using PAT tokens for example - such that every runner is associated with an owner.

## Implementation plan

| Component        | Milestone | Changes |
|------------------|-----------|---------|
| GitLab Rails app | `15.x` (latest at `15.6`) | Deprecate `POST /api/v4/runners` endpoint for `16.0`. This hinges on a [proposal](https://gitlab.com/gitlab-org/gitlab/-/issues/373774) to allow deprecating REST API endpoints for security reasons. |
| GitLab Runner    | `15.x` (latest at `15.8`) | Add deprecation notice for `register` command for `16.0`. |
| GitLab Runner    | `15.x` | Ensure all runner entries in `config.toml` have unique system identifier values assigned. Log new system ID values with `INFO` level as they get created. |
| GitLab Runner    | `15.x` | Start additionally logging unique system ID anywhere we log the runner short SHA. |
| GitLab Rails app | `15.x` | Create database migrations to add settings from `application_settings` and `namaspace_settings` tables. |
| GitLab Runner    | `15.x` | Start sending `unique_id` value in `POST /jobs/request` request and other follow-up requests that require identifying the unique system. |
| GitLab Runner    | `15.x` | Implement new user-authenticated API (REST and GraphQL) to create a new runner. |
| GitLab Rails app | `15.x` | Implement UI to create new runner. |
| GitLab Runner    | `16.0` | Remove `register` command and support for `POST /runners` endpoint. |
| GitLab Rails app | `16.0` | Remove legacy UI showing registration with a registration token. |
| GitLab Rails app | `16.0` | Create database migrations to remove settings from `application_settings` and `namaspace_settings` tables. |
| GitLab Rails app | `16.0` | Make [`POST /api/v4/runners` endpoint](../../../api/runners.md#register-a-new-runner-deprecated) permanently return `410 Gone`. A future v5 version of the API would return `404 Not Found`. |
| GitLab Rails app | `16.0` | Start refusing job requests that don't include a unique ID. |

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

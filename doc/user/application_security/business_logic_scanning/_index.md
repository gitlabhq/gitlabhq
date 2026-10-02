---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Business logic scanning uses an AI agent to find authorization and access control vulnerabilities in your source code.
title: Business logic scanning
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/257199) in GitLab 19.5 [with feature flags](../../../administration/feature_flags/_index.md) named `bl_security_analyzer` (`experiment` type) and `agentic_analyzer_security_ingestion` (`gitlab_com_derisk` type). Disabled by default.
- Starting a scan from GitLab Duo Chat also requires the [feature flag](../../../administration/feature_flags/_index.md) named `duo_chat_flow_commands` (`wip` type). Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag. For more information, see the
> history.

Business logic scanning uses an AI agent to find vulnerabilities in how your application enforces
its own rules. Pattern-based analyzers like [SAST](../sast/_index.md) often miss these
vulnerabilities, because the code is valid and only the intent is wrong.

## What business logic scanning finds

Business logic scanning looks for vulnerabilities like:

- Broken object-level authorization (BOLA), also called insecure direct object references (IDOR).
  For example, an endpoint loads an invoice by the ID in the URL, and does not check that the
  invoice belongs to the authenticated user.
- Missing authorization. For example, an administrative action checks that the user is authenticated,
  but not that the user is an administrator.
- Mass assignment. For example, an update endpoint passes every request parameter to the model,
  so a user can change their own `role` or `is_admin` attribute.

## How business logic scanning works

Business logic scanning runs as a [GitLab Duo Agent Platform](../../duo_agent_platform/_index.md)
foundational flow, not as a job in your CI/CD pipeline. You do not add a template or a job to your
`.gitlab-ci.yml` file.

A scan starts in one of these ways:

| How the scan starts | What it scans | How to turn it on |
|---------------------|---------------|-------------------|
| [Automatically on merge requests](#automatic-merge-request-scans) | The files the merge request adds or modifies. A partial scan. | Attach the business logic scan profile to the project. |
| [From GitLab Duo Chat](#start-a-scan-from-gitlab-duo-chat) | The whole repository, on the default branch. The recommended way to scan the whole repository. | Send the flow command in GitLab Duo Chat. |
| [With the API](#start-a-scan-with-the-api) | The whole repository, on the default branch. | Send an API request. |
| [On a schedule](#scheduled-default-branch-scans) | Not available yet. | Not available yet. |

## Turn on business logic scanning

Prerequisites:

- A GitLab Ultimate subscription.
- [GitLab Duo Agent Platform turned on](../../duo_agent_platform/turn_on_off.md) for the
  top-level group.
- The `bl_security_analyzer` feature flag enabled for the top-level group. To show results, the
  `agentic_analyzer_security_ingestion` feature flag must also be enabled for each project you
  scan. On GitLab Self-Managed,
  an administrator must enable these feature flags.

To turn on business logic scanning:

1. As a user with the Owner role for the top-level group,
   [turn on foundational flows](../../duo_agent_platform/flows/foundational_flows/_index.md#turn-foundational-flows-on-or-off),
   including the **Business Logic Security Scan** flow.
1. [Attach the business logic scan profile](../configuration/security_configuration_profiles.md#business-logic-profile)
   to each project you want to scan. Until the scan profile UI is available,
   [attach the profile with the GraphQL API](../configuration/security_configuration_profiles.md#apply-a-profile-with-the-graphql-api).

## Automatic merge request scans

When a project has the business logic scan profile attached, a scan runs on each merge request:

- The scan runs on the merge request's head pipeline: either a merge request pipeline or a branch pipeline
  of an open merge request.
- The scan starts after the pipeline succeeds. If the pipeline fails, or the project has no CI/CD
  pipelines, no scan runs.
- The scan checks only the files the merge request adds or modifies.
- The user who ran the pipeline must be a human user with at least the Developer role and access
  to GitLab Duo Agent Platform.

These merge requests are not scanned:

- Merge requests from a fork.
- Merge requests that only delete files.
- Merge requests whose pipeline was run by a bot, like a project access token or a service
  account.
- Merge train pipelines, and merge request pipelines that a newer commit has replaced.

Because a merge request scan checks only the changed files, it is a partial scan, like GitLab
Advanced SAST [diff-based scanning](../sast/gitlab_advanced_sast.md#diff-based-scanning).
Vulnerabilities in files that it did not scan are not reported as fixed.

## Scheduled default-branch scans

Scheduled scans are not available yet. Automatic scans do not run on the default branch. To scan
the default branch, [start a scan from GitLab Duo Chat](#start-a-scan-from-gitlab-duo-chat) or
[with the API](#start-a-scan-with-the-api).

## Start a scan from GitLab Duo Chat

To scan the whole repository, start a scan from GitLab Duo Chat. The scan checks the default
branch, and runs as a GitLab Duo Agent Platform session that you can follow. Results appear in
the [vulnerability report](../vulnerability_report/_index.md).

Prerequisites:

- You must have at least the Developer role for the project.
- You must meet the [GitLab Duo Agent Platform prerequisites](../../duo_agent_platform/_index.md#prerequisites).
- The `bl_security_analyzer`, `agentic_analyzer_security_ingestion`, and `duo_chat_flow_commands`
  feature flags must be enabled, and the **Business Logic Security Scan** flow must be turned on.
  The project does not need the business logic scan profile.

To start a scan:

1. In the top bar, select **Search or go to** and find your project.
1. Open [GitLab Duo Chat](../../gitlab_duo_chat/agentic_chat.md#use-gitlab-duo-chat-in-the-gitlab-ui)
   and ensure the **Agentic** toggle is turned on.
1. In the chat text box, type `/flow:` and select **Business Logic Security Scan**.
1. Send the command without any other text.
1. Follow the scan in the agent session. When the session finishes, the results appear in the
   vulnerability report.

The scan's CI/CD job runs as the flow's service account.

> [!warning]
> Do not add a merge request number or other text after the command. A scan from GitLab Duo Chat
> always runs on the default branch, so it scans the whole repository, not the merge request's
> changes.

## Start a scan with the API

You can start a full scan of the default branch with the
[GitLab Duo Agent Platform flows API](../../../api/duo_agent_platform_flows.md#trigger-a-flow).
The scan runs on your behalf, with your permissions and your GitLab Duo Agent Platform access,
and checks the whole repository. Results appear in the vulnerability report.

Prerequisites:

- You must have at least the Developer role for the project.
- You must have a personal access token with the `api` scope.
- The `bl_security_analyzer` and `agentic_analyzer_security_ingestion` feature flags must be enabled,
  and the **Business Logic Security Scan** flow must be turned on. The project does not need the
  business logic scan profile.

To start a scan, send a request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --data "project_id=<project_id>" \
  --data "workflow_definition=bl_security/experimental" \
  --data "start_workflow=true" \
  --url "https://gitlab.example.com/api/v4/ai/duo_workflows/workflows"
```

Instead of `workflow_definition`, you can pass `ai_catalog_item_consumer_id` with the ID of the
project's **Business Logic Security Scan** flow consumer. To get the ID, use the GraphQL
`aiCatalogConfiguredItems` query, as described in
[look up the consumer ID](../../../api/duo_agent_platform_flows.md#look-up-the-consumer-id).

To scan only the files a merge request changes, pass the merge request IID as the `goal`, and
the merge request's source branch as the `source_branch`. The merge request must not come from a
fork. On any branch other than the default branch, the [`BL_TARGET_FILES`](#configure-a-scan)
CI/CD variable, when set, replaces the merge request's changed files. Otherwise, the scan checks
the whole repository.

## View results

Business logic scanning reports vulnerabilities in the same places as other security scanners:

- In the [merge request security widget](../detect/security_scanning_results.md#merge-request-reports),
  for merge request scans.
- In the vulnerability report, for scans of the default branch.

## Configure a scan

To change how business logic scanning runs, add
[project CI/CD variables](../../../ci/variables/_index.md#for-a-project). Set the environment
scope to **All (default)**. Variables with other scopes are ignored.

Protected and file-type variables are ignored. Define these as regular, unprotected variables with
the `*` environment scope.

| CI/CD variable    | Description |
|-------------------|-------------|
| `BL_SCAN_EFFORT`  | The scan's effort tier: `low`, `standard`, or `high`. When unset, blank, or any other value, the tier is `low`. A higher tier scans more deeply and uses more GitLab Duo Agent Platform usage. |
| `BL_TARGET_FILES` | A newline- or comma-separated list of file paths to scan. Applies to scans on any branch other than the default branch, and replaces the files the merge request changes. Ignored on the default branch, so scans of the default branch check the whole repository. |

The scan reads these variables from the project's CI/CD settings when it starts. Variables set in
`.gitlab-ci.yml` or when you run a pipeline do not apply.

## Known issues

Business logic scanning has the following known issues:

- When a merge request changes more than 400 files, or its diff is too large to collect, the scan
  does not limit itself to the changed files. It runs a full scan of the repository instead, and
  the result is not a partial scan.
- A scan analyzes up to a fixed amount of code. A scan that reaches this limit still counts as a
  full scan. Vulnerabilities in code that the scan skipped can be marked as no longer detected,
  and reappear in a later scan.
- Scans run only when the feature flags in the prerequisites are enabled. Automatic scans run only
  for the users described in [automatic merge request scans](#automatic-merge-request-scans).
- Scheduled scans are not available yet. For details, see
  [scheduled default-branch scans](#scheduled-default-branch-scans).
- A scan from GitLab Duo Chat always runs on the default branch. If you add a merge request
  number or other text after the flow command, the scan still checks the whole repository. It
  does not check the merge request's changes. Send the command
  without any other text. To scan a merge request's changes, [use the API](#start-a-scan-with-the-api).

## Cost

Each scan is a GitLab Duo Agent Platform session, and consumes
[GitLab Credits](../../../subscriptions/gitlab_credits.md). A scan of a large merge request, or of a
whole repository, uses more than a scan of a small change.

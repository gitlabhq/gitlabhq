---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Security report ingestion overview
---

WARNING:
The `Vulnerability::Feedback` model is currently undergoing deprecation and should be actively avoided in all further development. It is currently maintained with feature parity to enable revert should any issues arise, but is intended to be removed in 16.0. Any interactions relating to the Feedback model are superseded by the `StateTransition`, `IssueLink`, and `MergeRequestLink` models. You can find out more on [in this epic](https://gitlab.com/groups/gitlab-org/-/epics/5629).

## Commonly used terms

### Feedback

An instance of `Vulnerabilities::Feedback` class. They are created to keep track of users' interactions with Vulnerability Findings before they are promoted to a Vulnerability. This model is deprecated and due to be removed by GitLab 16.0 as part of the [Deprecate and remove Vulnerabilities::Feedback epic](https://gitlab.com/groups/gitlab-org/-/epics/5629).

### Issue Link

An instance of `Vulnerabilities::IssueLink` class. They are used to link `Vulnerability` records to `Issue` records.

### Merge Request Link

An instance of `Vulnerabilities::MergeRequestLink` class. They are used to link `Vulnerability` records to `MergeRequest` records.

### Security Finding

An instance of `Security::Finding` class. These serve as a meta-data store of a specific vulnerability detected in a specific `Security::Scan`. They currently store **partial** finding data to improve performance of the pipeline security report. This class has been extended to store almost all required scan information so we can stop relying on job artifacts and is [due to be used in favor of `Vulnerability::Findings` soon.](https://gitlab.com/gitlab-org/gitlab/-/issues/393394)

### Security Scan

An instance of the `Security::Scan` class. Security scans are representative of a `Ci::Build` which output a `Job Artifact` which has been output as a security scan result, which GitLab acknowledges and ingests the findings of as `Security::Finding` records.

### State Transition

An instance of the `Vulnerabilities::StateTransition` class. This model represents a state change of a respective Vulnerability record, for example the dismissal of a vulnerability which has been determined to be safe.

### Vulnerability

An instance of `Vulnerability` class. A `Vulnerability` is representative of a `Vulnerability::Finding` which has been detected in the default branch of the project, or if the `present_on_default_branch` flag is false, is representative of a finding which has been interacted with in some way outside of the default branch, such as if it is dismissed (`State Transition`), or linked to an `Issue` or `Merge Request`. They are created based on information available in `Vulnerabilities::Finding` class. Every `Vulnerability` **must have** a corresponding `Vulnerabilities::Finding` object to be valid, however this is not enforced at the database level.

### Finding

An instance of `Vulnerabilities::Finding` class. A `Vulnerability::Finding` is a database only representation of a security finding which has been merged into the default branch of a project, as the same `Vulnerability` may be present in multiple places within a project. This class was previously called `Vulnerabilities::Occurrence`; after renaming the class, we kept the associated table name `vulnerability_occurrences` due to the effort involved in renaming large tables.

### Identifier

An instance of the `Vulnerabilities::Identifier` class. Each vulnerability is given a unique identifier that can be derived from it's finding, enabling multiple Findings of the same `Vulnerability` to be correlated accordingly.

### Vulnerability Read

An instance of the `Vulnerabilities::Read` class. This is a denormalized record of `Vulnerability` and `Vulnerability::Finding` data to improve performance of filtered querying of vulnerability data to the front end.

### Remediation

An instance of the `Vulnerabilities::Remediation` class. A remediation is representative of a known solution to a detected `Vulnerability`. These enable GitLab to recommend a change to resolve a specific `Vulnerability`.

## Vulnerability creation from Security Reports

Assumptions:

- Project uses GitLab CI
- Project uses [security scanning tools](../../user/application_security/_index.md)
- No Vulnerabilities are present in the database
- All pipelines perform security scans

### Scan runs in a pipeline for a non-default branch

1. Code is pushed to the branch.
1. GitLab CI runs a new pipeline for that branch.
1. Pipeline status transitions to any of [`::Ci::Pipeline.completed_statuses`](https://gitlab.com/gitlab-org/gitlab/-/blob/354261b2fe4fc5b86d1408467beadd90e466ce0a/app/models/concerns/ci/has_status.rb#L12).
1. `Security::StoreScansWorker` is called and it schedules `Security::StoreScansService`.
1. `Security::StoreScansService` calls `Security::StoreGroupedScansService` and schedules `ScanSecurityReportSecretsWorker`.
1. `Security::StoreGroupedScansService` calls `Security::StoreScanService`.
1. `Security::StoreScanService` calls `Security::StoreFindingsService`.
1. `ScanSecurityReportSecretsWorker` calls `Security::TokenRevocationService` to automatically revoke any leaked keys that were detected.

At this point we **only** have `Security::Finding` records, rather than `Vulnerability` records, as these findings are not present in the default branch of the project.
Some of the scenarios where these `Security::Finding` records may be promoted to `Vulnerability` records are described below.

### Scan runs in a pipeline for the default branch

If the pipeline ran on the default branch then the following steps, in addition to the steps in [Scan runs in a pipeline for a non-default branch](#scan-runs-in-a-pipeline-for-a-non-default-branch), are executed:

1. `Security::StoreScansService` gets called and schedules `StoreSecurityReportsByProjectWorker`.
1. `StoreSecurityReportsByProjectWorker` executes `Security::Ingestion::IngestReportsService`.
1. `Security::Ingestion::IngestReportsService` takes all reports from a given Pipeline and calls `Security::Ingestion::IngestReportService` and then calls `Security::Ingestion::MarkAsResolvedService`.
1. `Security::Ingestion::IngestReportService` calls `Security::Ingestion::IngestReportSliceService` which executes a number of tasks for a report slice.

### Dismissal

If you change the state of a vulnerability, such as selecting `Dismiss vulnerability` the following things currently happen:

- A `Feedback` record of `dismissal` type is created to record the current state.
- If they do not already exist, a `Vulnerability Finding` and a `Vulnerability` with `present_on_default_branch: false` attribute get created, to which a `State Transition` reflecting the state change is related.

You can optionally add a comment to the state change which is recorded on both the `Feedback` and the `State Transition`.

### Issue or Merge Request creation

If you select `Create issue` or `Create merge request` the following things currently happen:

- A `Vulnerabilities::Feedback` record is created. The Feedback will have a `feedback_type` of `issue` or `merge request` and an `issue_id` or `merge_request_id` that's not `NULL` respective to the attachment.
- If they do not already exist, a `Vulnerability Finding` and a `Vulnerability` with `present_on_default_branch: false` attribute get created, to which a `Issue Link` or `Merge Request Link` will be related respective to the action taken.

## Vulnerabilities in the Default Branch

Security Findings detected in scan run on the default branch are saved as `Vulnerabilities` with the `present_on_default_branch: true` attribute and respective `Vulnerability Finding` records. `Vulnerability` records that already exist from interactions outside of the default branch will be updated to `present_on_default_branch: true`

`Vulnerabilities` which have already been interacted with will retain all existing `State Transitions`, `Merge Request Links` and `Issue Links`, as well as a corresponding `Vulnerability Feedback`.

## Vulnerability Read Creation

`Vulnerability::Read` records are created via PostgreSQL database trigger upon the creation of a `Vulnerability::Finding` record and as such are part of our ingestion process, though they have no impact on it bar it's denormalization performance benefits on the report pages.

This style of creation was intended to be fast and seamless, but has proven difficult to debug and maintain and may be [migrated to the application layer later](https://gitlab.com/gitlab-org/gitlab/-/issues/393912).

## No longer detected

The "No longer detected" badge on the vulnerability report is displayed if the `Vulnerability` record has `resolved_on_default_branch: true`.
This is set by `Security::Ingestion::MarkAsResolvedService` when a pipeline runs on the default branch. Vulnerabilities which have
`resolved_on_default_branch: false` and _are not_ present in the pipeline scan results are marked as resolved.
[Secret Detection](../../user/application_security/secret_detection/_index.md) and [manual](../../user/application_security/vulnerability_report/_index.md#manually-add-a-vulnerability)
vulnerabilities are excluded from this process.

---
stage: Secure
group: Threat Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts
---

# Security report ingestion overview

## Definitions

- **Vulnerability Finding** – an instance of `Vulnerabilities::Finding` class. This class was previously called `Vulnerabilities::Occurrence`; after renaming the class, we kept the associated table name `vulnerability_occurrences` due to the effort involved in renaming large tables.
- **Vulnerability** – an instance of `Vulnerability` class. They are created based on information available in `Vulnerabilities::Finding` class. Every `Vulnerability` **must have** a corresponding `Vulnerabilities::Finding` object to be valid, however this is not enforced at the database level.
- **Security Finding** – an instance of `Security::Finding` class. They store **partial** finding data to improve performance of the pipeline security report. We are working on extending this class to store almost all required information so we can stop relying on job artifacts.
- **Feedback** – an instance of `Vulnerabilities::Feedback` class. They are created to keep track of users' interactions with Vulnerability Findings before they are promoted to a Vulnerability. We are in the process of removing this model via [Deprecate and remove Vulnerabilities::Feedback epic](https://gitlab.com/groups/gitlab-org/-/epics/5629).
- **Issue Link** – an instance of `Vulnerabilities::IssueLink` class. They are used to link `Vulnerability` objects to `Issue` objects.

## Vulnerability creation from security reports

Assumptions:

- Project uses GitLab CI
- Project uses [security scanning tools](../../user/application_security)
- No Vulnerabilities are present in the database
- All pipelines perform security scans

1. Code is pushed to a branch that's **not** the default branch.
1. GitLab CI runs a new pipeline for that branch.
1. Pipeline status transitions to any of [`::Ci::Pipeline.completed_statuses`](https://gitlab.com/gitlab-org/gitlab/-/blob/354261b2fe4fc5b86d1408467beadd90e466ce0a/app/models/concerns/ci/has_status.rb#L12).
1. `Security::StoreScansWorker` is called and it schedules `Security::StoreScansService`.
1. `Security::StoreScansService` calls `Security::StoreGroupedScansService`.
1. `Security::StoreGroupedScansService` calls `Security::StoreScanService`.
1. `Security::StoreScanService` calls `Security::StoreFindingsService`.
1. At this point we have `Security::Finding` objects **only**.

At this point, the following things can happen to the `Security::Finding`:

- Dismissal
- Issue creation
- Promotion to a Vulnerability

If the pipeline ran on the default branch then the following, additional steps are done:

1. `Security::StoreScansService` gets called and schedules `Security::StoreSecurityReportsWorker`.
1. `Security::StoreSecurityReportsWorker` executes `Security::Ingestion::IngestReportsService`.
1. `Security::Ingestion::IngestReportsService` takes all reports from a given Pipeline and calls `Security::Ingestion::IngestReportService` and then calls `Security::Ingestion::MarkAsResolvedService`.
1. `Security::Ingestion::IngestReportService` calls `Security::Ingestion::IngestReportSliceService` which executes a number of tasks for a report slice.

### Dismissal

If you select `Dismiss vulnerability`, a Feedback is created. You can also dismiss it with a comment.

#### After Feedback removal

If there is only a Security Finding, a Vulnerability Finding and a Vulnerability get created. At the same time we create a `Vulnerabilities::StateTransition` record to indicate the Vulnerability was dismissed.

### Issue creation

If you select `Create issue`, a Vulnerabilities::Feedback record is created as well. The Feedback has a different `feedback_type` and an `issue_id` that’s not `NULL`.

NOTE:
Vulnerabilities::Feedback are in the process of being [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/5629). This will later create a `Vulnerabilities::IssueLink` record.

#### After Feedback removal

If there's only a Security Finding, a Vulnerability Finding and a Vulnerability gets created. At the same time, we create an Issue and a Issue Link.

## Promotion to a Vulnerability

If the branch with a Security Finding gets merged into the default branch, all Security Findings get promoted into Vulnerabilities. Promotion is the process of creating Vulnerability Findings and Vulnerability records from those Security Findings.

If there's a dismissal Feedback present for that Security Finding, the created Vulnerability is marked as dismissed.

If there's an issue Feedback present for that Security Finding, we also create an Issue Link for that Vulnerability.

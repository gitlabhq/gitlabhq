---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance status report
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186525) in GitLab 17.11 [with a flag](../../../administration/feature_flags.md) named `enable_standards_adherence_dashboard_v2`. Disabled by default.

{{< /history >}}

The compliance status report displays the most recent instances where projects do not adhere to [compliance framework requirements](../compliance_frameworks.md#requirements). It is part of the
Compliance Center, and helps you quickly identify and remediate gaps in control implementation across your projects.

## Scan timing and triggers

Compliance scans that update the status report are automatically triggered in the following situations:

- A framework is added to a project.
- The requirements of an associated framework are modified.
- A scheduled scan runs (every 12 hours).

After a scan is triggered, results can take 5 to 10 minutes to appear in the compliance status report.

To learn more about how requirements and controls are defined in a compliance framework, see [Create and manage compliance framework requirements](../compliance_frameworks.md#add-requirements).

## View the compliance status report

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance status report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the **Compliance reports** section, select **Compliance status report**.

## Report details

The compliance status report shows the latest instance where a project is **adhering or not adhering** to a framework control. Each row provides details
about the current status of a control in a specific project, helping you monitor compliance across your group.

You can:

- Filter the report by **project**, **framework**, or **control**.
- Navigate directly to a project's compliance detail view.
- Review when the non-adherence was first detected.

The compliance status report has the following columns:

- **Project**: The project with non-adherence.
- **Framework**: The compliance framework the control belongs to (for example, GitLab or SOC 2).
- **Control**: The specific control the project is not adhering to (for example, "At least two approvals").
- **Detected on**: The date and time the non-adherence was first recorded.
- **More info**: A link to additional context or related settings for the project.

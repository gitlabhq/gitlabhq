---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Browse and filter a unified record of GitLab Duo agent activity for compliance and governance purposes.
title: AI audit event report
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20237) in GitLab 19.1 as a [beta](../../policy/development_stages_support.md) with a [feature flag](../../administration/feature_flags/_index.md) named `agent_artifacts_page`. Disabled by default.

{{< /history >}}

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

The AI audit event report gives security and compliance teams a unified,
browsable record of GitLab Duo agent activity. Each agent session produces
a comprehensive audit artifact that you can inspect.

## View AI audit events

AI audit events are available on the **Governance** page as the
**Agent artifacts** tab.

Prerequisites:

- You have the Owner role for the top-level group.

To view AI audit events for a group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change governance**.
1. Select the **Agent artifacts** tab.

The tab displays a list of agent sessions. Each row shows:

- The agent type (workflow definition).
- The project the session ran in.
- The number of audit events in the session.
- The session start time.

## Filter sessions

You can filter the session list to narrow results:

- **Project**: Filter by project path, or exclude a specific project.
- **Date range**: Filter sessions created after or before a specific date.

## View session details

To inspect the events within a session:

1. Select a session row to open the session details panel.
   The panel shows session metadata and a chronological list of audit events.
1. Select an individual event to view its full details, including entity
   and target information.

## Related topics

- [GitLab Duo Agent Platform](_index.md)
- [Audit events](../../administration/compliance/audit_event_reports.md)

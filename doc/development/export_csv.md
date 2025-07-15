---
stage: Create
group: Import
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Export to CSV
---

This document lists the different implementations of CSV export in GitLab codebase.

| Export type                       | Implementation | Advantages | Disadvantages | Existing examples |
|-----------------------------------|----------------|------------|---------------|-------------------|
| Streaming                         | - Query and yield data in batches to a response stream.<br>- Download starts immediately. | - Report available immediately. | - No progress indicator.<br>- Requires a reliable connection. | [Export audit event log](../administration/compliance/audit_event_reports.md#exporting-audit-events) |
| Downloading                       | - Query and write data in batches to a temporary file.<br>- Loads the file into memory.<br>- Sends the file to the client. | - Report available immediately. | - Large amount of data might cause request timeout.<br>- Memory intensive.<br>- Request expires when the user goes to a different page. | - [Export Chain of Custody Report](../user/compliance/compliance_center/compliance_chain_of_custody_report.md)<br>- [Export License Usage File](../subscriptions/self_managed/_index.md#export-your-license-usage) |
| As email attachment               | - Asynchronously process the query with background job.<br>- Email uses the export as an attachment. | - Asynchronous processing. | - Requires users use a different app (email) to download the CSV.<br>- Email providers may limit attachment size. | - [Export issues](../user/project/issues/csv_export.md)<br>- [Export merge requests](../user/project/merge_requests/csv_export.md) |
| As downloadable link in email (*) | - Asynchronously process the query with background job.<br>- Email uses an export link. | - Asynchronous processing.<br>- Bypasses email provider attachment size limit. | - Requires users use a different app (email).<br>- Requires additional storage and cleanup. | [Export User Permissions](https://gitlab.com/gitlab-org/gitlab/-/issues/1772) |
| Polling (non-persistent state)    | - Asynchronously processes the query with the background job.<br>- Frontend(FE) polls every few seconds to check if CSV file is ready. | - Asynchronous processing.<br>- Automatically downloads to local machine on completion.<br>- In-app solution. | - Non-persistable request - request expires when the user goes to a different page.<br>- API is processed for each polling request. | [Export Vulnerabilities](../user/application_security/vulnerability_report/_index.md#exporting) |
| Polling (persistent state) (*)    | - Asynchronously processes the query with background job.<br>- Backend (BE) maintains the export state<br>- FE polls every few seconds to check status.<br>- FE shows 'Download link' when export is ready.<br>- User can download or regenerate a new report. | - Asynchronous processing.<br>- No database calls made during the polling requests (HTTP 304 status is returned until export status changes).<br>- Does not require user to stay on page until export is complete.<br>- In-app solution.<br>- Can be expanded into a generic CSV feature (such as dashboard / CSV API). | - Requires to maintain export states in DB.<br>- Does not automatically download the CSV export to local machine, requires users to select 'Download'. | [Export Merge Commits Report](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/43055) |

{{< alert type="note" >}}

Export types marked as * are currently work in progress.

{{< /alert >}}

---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Export merge requests to CSV
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Export all the data collected from a project's merge requests into a comma-separated values (CSV) file.

To export merge requests to a CSV file:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests**.
1. Add any searches or filters. This can help you keep the size of the CSV file under the 15 MB limit. The limit ensures
   the file can be emailed to a variety of email providers.
1. Select **Actions** (**{ellipsis_v}**) **> Export as CSV**.
1. Confirm the correct number of merge requests are to be exported.
1. Select **Export merge requests**.

## CSV Output

The following table shows the attributes in the CSV file.

| Column             | Description                                                  |
|--------------------|--------------------------------------------------------------|
| Title              | Merge request title                                          |
| Description        | Merge request description                                    |
| MR ID              | MR `iid`                                                     |
| URL                | A link to the merge request on GitLab                        |
| State              | Opened, Closed, Locked, or Merged                            |
| Source Branch      | Source branch                                                |
| Target Branch      | Target branch                                                |
| Source Project ID  | ID of the source project                                     |
| Target Project ID  | ID of the target project                                     |
| Author             | Full name of the merge request author                        |
| Author Username    | Username of the author, with the @ symbol omitted            |
| Assignees          | Full names of the merge request assignees, joined with a `,` |
| Assignee Usernames | Username of the assignees, with the @ symbol omitted         |
| Approvers          | Full names of the approvers, joined with a `,`               |
| Approver Usernames | Username of the approvers, with the @ symbol omitted         |
| Merged User        | Full name of the merged user                                 |
| Merged Username    | Username of the merge user, with the @ symbol omitted        |
| Milestone ID       | ID of the merge request milestone                            |
| Created At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS`                           |
| Updated At (UTC)   | Formatted as `YYYY-MM-DD HH:MM:SS`                           |

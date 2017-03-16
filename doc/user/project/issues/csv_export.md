# CSV Export

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1126) in [GitLab Enterprise Edition Starter](https://about.gitlab.com/products/) 9.0.

Issues can be exported as CSV from GitLab and are sent to your default notification email as an attachment.

## Choosing which issues to include

From the issues page you can narrow down which issues to export using the search bar, along with the All/Open/Closed tabs. All issues returned will be exported, including those not shown on the first page.

![CSV export button](img/csv_export_button.png)

You will be asked to confirm the number of issues and email address for the export, after which the email will begin being prepared.

![CSV export modal dialog](img/csv_export_modal.png)

## Format

Data will be encoded with a comma as the column delimiter, with `"` used to quote fields if needed, and newlines to separate rows. The first row will be the headers, which are listed in the following table along with a description of the values:


| Column  | Description |
|---------|-------------|
| Issue ID | Issue `iid` |
| URL | A link to the issue on GitLab |
| Title | Issue `title` |
| State | `Open` or `Closed` |
| Description | Issue `description` |
| Author | Full name of the issue author |
| Author Username | Username of the author, with the `@` symbol omitted |
| Assignee | Full name of the issue assignee |
| Assignee Username | Username of the author, with the `@` symbol omitted |
| Confidential | `Yes` or `No` |
| Due Date | Formated as `YYYY-MM-DD` |
| Created At (UTC) | Formated as `YYYY-MM-DD HH:MM:SS` |
| Updated At (UTC) | Formated as `YYYY-MM-DD HH:MM:SS` |
| Milestone | Title of the issue milestone |
| Labels | Title of any labels joined with a `,` |


## Limitations

As the issues will be sent as an email attachment, there is a limit on how much data can be exported. Currently this limit is 20MB to ensure successful delivery across a range of email providers. If this limit is reached we suggest narrowing the search before export, perhaps by exporting open and closed issues separately.

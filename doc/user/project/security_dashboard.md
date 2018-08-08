# Project Security Dashboard

> [Introduced][ee-6165] in [GitLab Ultimate][ee] 11.1.

The Security Dashboard displays the latest security reports for your project.
Use it to find and fix vulnerabilities affecting the [default branch](./repository/branches/index.md#default-branch).

![Project Security Dashboard](img/project_security_dashboard.png)

## How it works?

To benefit from the Security Dashboard you must first configure the [Security Reports](./merge_requests/index.md#security-reports).

The Security Dashboard will then list security vulnerabilities from the latest pipeline run on the default branch (e.g., `master`).
You will also be able to interact with the reports [the same way you can do on a merge request](./merge_requests/index.md#interacting-with-security-reports).

[ee-6165]: https://gitlab.com/gitlab-org/gitlab-ee/issues/6165
[ee]: https://about.gitlab.com/pricing

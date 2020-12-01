---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Bugzilla Service

Navigate to the [Integrations page](overview.md#accessing-integrations),
select the **Bugzilla** service and fill in the required details as described
in the table below.

| Field | Description |
| ----- | ----------- |
| `project_url`   | The URL to the project in Bugzilla which is being linked to this GitLab project. Note that the `project_url` requires PRODUCT_NAME to be updated with the product/project name in Bugzilla. |
| `issues_url`    | The URL to the issue in Bugzilla project that is linked to this GitLab project. Note that the `issues_url` requires `:id` in the URL. This ID is used by GitLab as a placeholder to replace the issue number. |
| `new_issue_url` | This is the URL to create a new issue in Bugzilla for the project linked to this GitLab project. Note that the `new_issue_url` requires PRODUCT_NAME to be updated with the product/project name in Bugzilla. |

Once you have configured and enabled Bugzilla, you see the Bugzilla link on the GitLab project pages that takes you to the appropriate Bugzilla project.

## Referencing issues in Bugzilla

Issues in Bugzilla can be referenced in two alternative ways:

- `#<ID>` where `<ID>` is a number (example `#143`).
- `<PROJECT>-<ID>` where `<PROJECT>` starts with a capital letter which is
  then followed by capital letters, numbers or underscores, and `<ID>` is
  a number (example `API_32-143`).

We suggest using the longer format if you have both internal and external issue trackers enabled. If you use the shorter format and an issue with the same ID exists in the internal issue tracker, the internal issue is linked.

Please note that `<PROJECT>` part is ignored and links always point to the
address specified in `issues_url`.

## Troubleshooting

To see recent service hook deliveries, check [service hook logs](overview.md#troubleshooting-integrations).

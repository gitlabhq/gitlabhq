---
stage: Govern
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Available custom abilities

The following abilities are available. You can add these abilities in any combination
to a base role to create a custom role.

Some abilities require having other abilities enabled first. For example, administration of vulnerabilities (`admin_vulnerability`) can only be enabled if reading vulnerabilities (`read_vulnerability`) is also enabled.

These requirements are documented in the `Required ability` column in the following table.

| Ability                      | Version                | Required ability  | Description |
| ------------------------------- | -----------------------| -------------------- | ----------- |
| `read_code`                     | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106256) in GitLab 15.7 [with a flag](../../administration/feature_flags.md) named `customizable_roles`. [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114524) in GitLab 15.10.| Not applicable       | View project code. Does not include the ability to pull code.  |
| `read_vulnerability`            | [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10160) in GitLab 16.1 [with a flag](../../administration/feature_flags.md) named `custom_roles_vulnerability`. [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124049) in GitLab 16.2. | Not applicable       | View [vulnerability reports](../application_security/vulnerability_report/index.md).  |
| `admin_vulnerability`           | [Introduced in GitLab 16.1](https://gitlab.com/gitlab-org/gitlab/-/issues/412536).  | `read_vulnerability` | Change the [status of vulnerabilities](../application_security/vulnerabilities/index.md#vulnerability-status-values).  |
| `read_dependency`               | [Introduced in GitLab 16.3](https://gitlab.com/gitlab-org/gitlab/-/issues/415255).  | Not applicable       | View [project dependencies](../application_security/dependency_list/index.md).  |
| `admin_merge_request`           | [Introduced in GitLab 16.4](https://gitlab.com/gitlab-org/gitlab/-/issues/412708).  | Not applicable       | View and approve [merge requests](../project/merge_requests/index.md), revoke merge request approval, and view the associated merge request code. <br> Does not allow users to view or change merge request approval rules.  |
| `manage_project_access_tokens`  | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/421778) in GitLab 16.5 [with a flag](../../administration/feature_flags.md) named `manage_project_access_tokens`  | Not applicable       | Create, delete, and list [project access tokens](../project/settings/project_access_tokens.md).  |
| `admin_group_member`            | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17364) in GitLab 16.5  | Not applicable       | Add or remove [group members](../group/manage.md).  |
| `archive_project`               | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/425957) in GitLab 16.7  | Not applicable       | [Archive and unarchive projects](../project/settings/migrate_projects.md#archive-a-project).  |
| `remove_project`                | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/425959) in GitLab 16.8  | Not applicable       | [Delete projects](../project/working_with_projects.md#delete-a-project).  |
| `manage_group_access_tokens`    | [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/428353) in GitLab 16.8  | Not applicable       | [Create, delete, and list group access tokens](../group/settings/group_access_tokens.md).  |

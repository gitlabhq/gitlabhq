# Bulk editing issues, merge requests, and epics at the group level **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/7249) for issues in [GitLab Premium](https://about.gitlab.com/pricing/) 12.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/12719) for merge requests in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/7250) for epics in [GitLab Premium](https://about.gitlab.com/pricing/) 12.2.

## Editing milestones and labels

> **Notes:**
>
> - A permission level of `Reporter` or higher is required in order to manage issues.
> - A permission level of `Developer` or higher is required in order to manage merge requests.
> - A permission level of `Reporter` or higher is required in order to manage epics.

By using the bulk editing feature:

- Milestones can be updated simultaneously across multiple issues or merge requests.
- Labels can be updated simultaneously across multiple issues, merge requests, or epics.

![Bulk editing](img/bulk-editing.png)

To bulk update group issues, merge requests, or epics:

1. Navigate to the issues, merge requests, or epics list.
1. Click **Edit issues**, **Edit merge requests**, or **Edit epics**.
    - This will open a sidebar on the right-hand side where editable fields
      for milestones and labels will be displayed.
    - Checkboxes will also appear beside each issue, merge request, or epic.
1. Check the checkbox beside each issue, merge request, or epic to be edited.
1. Select the desired new values from the sidebar.
1. Click **Update all**.

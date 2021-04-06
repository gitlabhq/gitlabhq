---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Linked issues **(FREE)**

> The simple "relates to" relationship [moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212329) to [GitLab Free](https://about.gitlab.com/pricing/) in 13.4.

Linked issues are a bi-directional relationship between any two issues and appear in a block below
the issue description. Issues can be across groups and projects.

The relationship only shows up in the UI if the user can see both issues. When you try to close an
issue that has open blockers, a warning is displayed.

NOTE:
To manage linked issues through our API, visit the [issue links API documentation](../../../api/issue_links.md).

## Add a linked issue

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/2035) in GitLab 12.8.
> - [Improved](https://gitlab.com/gitlab-org/gitlab/-/issues/34239) to warn when attempting to close an issue that is blocked by others in GitLab 13.0.
>   When you try to close an issue with open blockers, you see a warning that you can dismiss.

1. Link one issue to another by selecting the add linked issue button (**{plus}**) in the
   **Linked issues** section of an issue.

1. Select the relationship the between the two issues. Either:
   - **relates to**
   - **blocks** **(PREMIUM)**
   - **is blocked by** **(PREMIUM)**
1. Input the issue number or paste in the full URL of the issue.

   ![Adding a related issue](img/related_issues_add_v12_8.png)

   Issues of the same project can be specified just by the reference number.
   Issues from a different project require additional information like the
   group and the project name. For example:

   - The same project: `#44`
   - The same group: `project#44`
   - Different group: `group/project#44`

   Valid references are added to a temporary list that you can review.

1. When you have added all the linked issues, select **Add**.

When you have finished adding all linked issues, you can see
them categorized so their relationships can be better understood visually.

![Related issue block](img/related_issue_block_v12_8.png)

You can also add a linked issue from a commit message or the description in another issue or MR.
[Learn more about crosslinking issues](crosslinking_issues.md).

## Remove a linked issue

In the **Linked issues** section of an issue, click the remove button (**{close}**) on the
right-side of each issue token to remove.

Due to the bi-directional relationship, the relationship no longer appears in either issue.

![Removing a related issue](img/related_issues_remove_v12_8.png)

Access our [permissions](../../permissions.md) page for more information.

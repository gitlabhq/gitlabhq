# Related issues **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1797) in [GitLab Starter](https://about.gitlab.com/pricing/) 9.4.

Related issues are a bi-directional relationship between any two issues
and appear in a block below the issue description. Issues can be across groups
and projects.

The relationship only shows up in the UI if the user can see both issues.

## Adding a related issue

You can relate one issue to another by clicking the related issues "+" button
in the header of the related issue block. Then, input the issue reference number
or paste in the full URL of the issue.

Issues of the same project can be specified just by the reference number.
Issues from a different project require additional information like the
group and the project name. For example:

- same project: `#44`
- same group: `project#44 `
- different group: `group/project#44`

Valid references will be added to a temporary list that you can review.
When ready, click the green "Add related issues" button to submit.

![Adding a related issue](img/related_issues_add.png)

## Removing a related issue

In the related issues block, click the "x" icon on the right-side of each issue
token that you wish to remove. Due to the bi-directional relationship, it
will no longer appear in either issue.

![Removing a related issue](img/related_issues_remove.png)

Please access our [permissions](../../permissions.md) page for more information.

Additionally, you are also able to manage related issues through [our API](../../../api/issue_links.md).

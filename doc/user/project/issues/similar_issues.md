# Similar issues

> [Introduced][ce-22866] in GitLab 11.6.

Similar issues suggests issues that are similar when new issues are being created.
This features requires [GraphQL] to be enabled.

![Similar issues](img/similar_issues.png)

You can see the similar issues when typing in the title in the new issue form.
This searches both titles and descriptions across all issues the user has access
to in the current project. It then displays the first 5 issues sorted by most
recently updated.

[GraphQL]: ../../../api/graphql/index.md
[ce-22866]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/22866

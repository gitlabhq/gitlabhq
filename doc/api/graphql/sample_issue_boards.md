---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Identify issue boards by using GraphQL
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can identify [issue boards](../../user/project/issue_board.md) for a project by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Use GraphiQL

You can use GraphiQL to list the issue boards for a project.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window. This query
   gets issue boards for the `docs-gitlab-com` repository.

   ```graphql
   query {
     project(fullPath: "gitlab-org/technical-writing/docs-gitlab-com") {
       name
       forksCount
       statistics {
         wikiSize
       }
       issuesEnabled
       boards {
         nodes {
           id
           name
         }
       }
     }
   }
   ```

1. Select **Play**.

To view one of these issue boards, copy a numeric identifier from the output.
For example, if the identifier is `7174622`, use this URL to go to the issue board:

```http
https:/gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/boards/7174622
```

## Related topics

- [GraphQL API reference](reference/_index.md)

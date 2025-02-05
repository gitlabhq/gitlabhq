---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Identify issue boards by using GraphQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can identify [issue boards](../../user/project/issue_board.md) for a project by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Use GraphiQL

You can use GraphiQL to list the issue boards for a project.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window. This query
   gets issue boards for the `gitlab-docs` repository.

   ```graphql
   query {
     project(fullPath: "gitlab-org/gitlab-docs") {
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
For example, if the identifier is `105011`, use this URL to go to the issue board:

```http
https://gitlab.com/gitlab-org/gitlab-docs/-/boards/105011
```

## Related topics

- [GraphQL API reference](reference/_index.md)

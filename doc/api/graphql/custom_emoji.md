---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use custom emoji with GraphQL
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911) in GitLab 13.6 [with a flag](../../administration/feature_flags.md) named `custom_emoji`. Disabled by default.
> - Enabled on GitLab.com in GitLab 14.0.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969) in GitLab 16.7.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/) in GitLab 16.9. Feature flag `custom_emoji` removed.

To use [custom emoji](../../user/emoji_reactions.md) in comments and descriptions,
you can add them to a top-level group by using the GraphQL API.

## Create a custom emoji

```graphql
mutation CreateCustomEmoji($groupPath: ID!) {
  createCustomEmoji(input: {groupPath: $groupPath, name: "party-parrot", url: "https://cultofthepartyparrot.com/parrots/hd/parrot.gif"}) {
    clientMutationId
    customEmoji {
      name
    }
    errors
  }
}
```

After you add a custom emoji to the group, members can use it in the same way as other emoji in the comments.

### Attributes

The query accepts these attributes:

| Attribute    | Type           | Required               | Description |
| :----------- | :------------- | :--------------------- | :---------- |
| `group_path` | integer/string | Yes | ID or [URL-encoded path of the top-level group](../rest/_index.md#namespaced-paths). |
| `name`       | string         | Yes | Name of the custom emoji. |
| `file`       | string         | Yes | URL of the custom emoji image. |

## Use GraphiQL

You can use GraphiQL to query the emoji for a group.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window.
   In this query, `gitlab-org` is the group path.

   ```graphql
       query GetCustomEmoji {
         group(fullPath: "gitlab-org") {
           id
           customEmoji {
             nodes {
               name,
               url
             }
           }
         }
       }
   ```

1. Select **Play**.

## Related topics

- [GraphQL API reference](reference/_index.md)
- [GraphQL-specific entities, like fragments and interfaces](https://graphql.org/learn/)

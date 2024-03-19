---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Use custom emoji with GraphQL

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37911) in GitLab 13.6 [with a flag](../../administration/feature_flags.md) named `custom_emoji`. Disabled by default.
> - Enabled on GitLab.com in GitLab 14.0.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138969) in GitLab 16.7.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/) in GitLab 16.9. Feature flag `custom_emoji` removed.

To use [custom emoji](../../user/emoji_reactions.md) in comments and descriptions, you can add them to a top-level group using the GraphQL API.

Parameters:

| Attribute    | Type           | Required               | Description                                                               |
| :----------- | :------------- | :--------------------- | :------------------------------------------------------------------------ |
| `group_path` | integer/string | Yes | ID or [URL-encoded path of the top-level group](../rest/index.md#namespaced-path-encoding) |
| `name`       | string         | Yes | Name of the custom emoji.                                                 |
| `file`       | string         | Yes | URL of the custom emoji image.                                            |

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

After adding a custom emoji to the group, members can use it in the same way as other emoji in the comments.

## Get custom emoji for a group

```graphql
query GetCustomEmoji($groupPath: ID!) {
  group(fullPath: $groupPath) {
    id
    customEmoji {
      nodes {
        name
      }
    }
  }
}
```

## Set up the GraphiQL explorer

This procedure presents a substantive example that you can copy and paste into GraphiQL
explorer. GraphiQL explorer is available for:

- GitLab.com users at [https://gitlab.com/-/graphql-explorer](https://gitlab.com/-/graphql-explorer).
- Self-managed users at `https://gitlab.example.com/-/graphql-explorer`.

1. Copy the following code excerpt:

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

1. Open the [GraphiQL explorer tool](https://gitlab.com/-/graphql-explorer).
1. Paste the `query` listed above into the left window of your GraphiQL explorer tool.
1. Select **Play** to get the result shown here:

![GraphiQL explore custom emoji query](img/custom_emoji_query_example.png)

For more information on:

- GraphQL specific entities, such as Fragments and Interfaces, see the official
  [GraphQL documentation](https://graphql.org/learn/).
- Individual attributes, see the [GraphQL API Resources](reference/index.md).

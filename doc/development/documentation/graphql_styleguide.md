---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Writing styles, markup, formatting, and other standards for GraphQL API's GitLab Documentation."
title: Creating a GraphQL example page
---

GraphQL APIs are different from [RESTful APIs](restful_api_styleguide.md). Reference
information is generated in our [GraphQL API resources](../../api/graphql/reference/_index.md) page.

However, it's helpful to include examples for how to use GraphQL for different
use cases, with samples that readers can use directly in the GraphQL explorer, called
[GraphiQL](../api_graphql_styleguide.md#graphiql).

This section describes the steps required to add your GraphQL examples to
GitLab documentation.

## Add a dedicated GraphQL page

To create a dedicated GraphQL page, create a new `.md` file in the
`doc/api/graphql/` directory. Give the file a functional name, like
`import_from_specific_location.md`.

## Add metadata

Add descriptive content and a title at the top of the page, for example:

```markdown
---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# List branch rules for a project by using GraphQL

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated
```

For help editing this content for your use case, ask a technical writer.

## Add content

Now add the body text. You can use this content as a starting point
and replace the text with your own information.

```markdown
You can query for branch rules in a given project by using:

- GraphiQL.
- [`cURL`](getting_started.md#command-line).

## Use GraphiQL

You can use GraphiQL to list the branch rules for a project.

1. Open GraphiQL:
   - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
   - For GitLab Self-Managed, use: `https://gitlab.example.com/-/graphql-explorer`
1. Copy the following text and paste it in the left window.

   <graphql codeblock here>

1. Select **Play**.

## Related topics:

- [GraphQL API reference](reference/index.md)
```

## Add the GraphQL example to the global navigation

Include a link to your new document in the global navigation (the list on the
left side of the documentation website). To do so, open a second MR, against the
[GitLab documentation repository](https://gitlab.com/gitlab-org/gitlab-docs/).

The global navigation is set in the
[`navigation.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/content/_data/navigation.yaml) file,
in the `content/_data` subdirectory. You can find the GraphQL section under the
following line:

```yaml
- category_title: GraphQL
```

Be aware that CI tests for that second MR will fail with a bad link until the
main MR that adds the new GraphQL page is merged. Therefore, only merge the MR against the
[`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) repository after the content has
been merged and live on `docs.gitlab.com`.

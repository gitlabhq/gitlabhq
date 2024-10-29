---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Writing styles, markup, formatting, and other standards for GraphQL API's GitLab Documentation."
---

# Creating a GraphQL example page

GraphQL APIs are different from [RESTful APIs](restful_api_styleguide.md). Reference
information is generated in our [GraphQL API resources](../../api/graphql/reference/index.md) page.

However, it's helpful to include examples for how to use GraphQL for different
use cases, with samples that readers can use directly in the GraphQL explorer, called
[GraphiQL](../api_graphql_styleguide.md#graphiql).

This section describes the steps required to add your GraphQL examples to
GitLab documentation.

## Add a dedicated GraphQL page

To create a dedicated GraphQL page, create a new `.md` file in the
`doc/api/graphql/` directory. Give the file a functional name, like
`import_from_specific_location.md`.

## Start the page with an explanation

Include a page title that describes the GraphQL functionality in a few words,
like:

```markdown
# Search for [substitute kind of data]
```

Describe the search. One sentence may be all you need. More information may
help readers learn how to use the example for their GitLab deployments.

## Include a procedure that uses GraphiQL

GraphiQL can help readers test queries against their working deployments.
Create a task to help guide them.

- Use the following title:

  ```markdown
  ## Use GraphiQL
  ```

- Include a code block with the query that anyone can include in their
  instance of GraphiQL:

  ````markdown
  ```graphql
  query {
    <insert queries here>
  }
  ```
  ````

- Tell the user what to do:

  ```markdown
  1. Open GraphiQL:
     - For GitLab.com, use: `https://gitlab.com/-/graphql-explorer`
     - For self-managed GitLab, use: `https://gitlab.example.com/-/graphql-explorer`
  1. Paste the `query` listed previously into the left window of GraphiQL.
  1. Select **Play**.
  ```

- Include the results from GraphiQL.
- Follow up with an example of what you can do with the output. Make sure the
  example is something that readers can do on their own deployments.
- Include a link to the [GraphQL API resources](../../api/graphql/reference/index.md).

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

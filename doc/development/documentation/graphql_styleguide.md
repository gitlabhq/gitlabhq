---
type: reference, dev
stage: none
group: Development
info: "See the Technical Writers assigned to Development Guidelines: https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments-to-development-guidelines"
description: "Writing styles, markup, formatting, and other standards for GraphQL API's GitLab Documentation."
---

# GraphQL API

GraphQL APIs are different from [RESTful APIs](restful_api_styleguide.md). Reference
information is generated in our [GraphQL reference](../../api/graphql/reference/index.md).

However, it's helpful to include examples on how to use GraphQL for different
*use cases*, with samples that readers can use directly in the
[GraphiQL explorer](../api_graphql_styleguide.md#graphiql).

This section describes the steps required to add your GraphQL examples to
GitLab documentation.

## Add a dedicated GraphQL page

To create a dedicated GraphQL page, create a new `.md` file in the
`doc/api/graphql/` directory. Give that file a functional name, such as
`import_from_specific_location.md`.

## Start the page with an explanation

Include a page title that describes the GraphQL functionality in a few words,
such as:

```markdown
# Search for [substitute kind of data]
```

Describe the search. One sentence may be all you need. More information may
help readers learn how to use the example for their GitLab deployments.

## Include a procedure using the GraphiQL explorer

The GraphiQL explorer can help readers test queries with working deployments.
Set up the section with the following:

- Use the following title:

  ```markdown
  ## Set up the GraphiQL explorer
  ```

- Include a code block with the query that anyone can include in their
  instance of the GraphiQL explorer:

  ````markdown
  ```graphql
  query {
    <insert queries here>
  }
  ```
  ````

- Tell the user what to do:

  ```markdown
  1. Open the GraphiQL explorer tool in the following URL: `https://gitlab.com/-/graphql-explorer`.
  1. Paste the `query` listed above into the left window of your GraphiQL explorer tool.
  1. Select **Play** to get the result shown here:
  ```

- Include a screenshot of the result in the GraphiQL explorer. Follow the naming
  convention described in the [Save the image](styleguide/index.md#save-the-image) section of the Documentation style guide.
- Follow up with an example of what you can do with the output. Make sure the
  example is something that readers can do on their own deployments.
- Include a link to the [GraphQL API resources](../../api/graphql/reference/index.md).

## Add the GraphQL example to the global navigation

You should include a link for your new document in the global navigation (the list on the
left side of the documentation website). To do so, open a second MR, against the
[GitLab documentation repository](https://gitlab.com/gitlab-org/gitlab-docs/).

We store our global navigation in the [`navigation.yaml`](https://gitlab.com/gitlab-org/gitlab-docs/-/blob/main/content/_data/navigation.yaml) file, in the
`content/_data` subdirectory. You can find the GraphQL section under the
following line:

```yaml
- category_title: GraphQL
```

Be aware that CI tests for that second MR will fail with a bad link until the
main MR that adds the new GraphQL page is merged. Therefore, only merge the MR against the
[`gitlab-docs`](https://gitlab.com/gitlab-org/gitlab-docs) repository after the content has
been merged and live on `docs.gitlab.com`.

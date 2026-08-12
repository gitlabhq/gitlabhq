import { parse as parseGraphQL, print } from 'graphql';
import {
  parseQueryTextWithFrontmatter,
  parse,
  parseQuery,
  parseYAMLConfig,
} from '~/glql/core/parser';

const prettify = (query) => print(parseGraphQL(query));

const MOCK_FIELDS = 'title, author, state, description';

describe('parseQueryTextWithFrontmatter', () => {
  it('separates the presentation layer from the query and returns an object', () => {
    const text = `---
fields: title, assignees, dueDate
display: list
---
assignee = currentUser()`;

    expect(parseQueryTextWithFrontmatter(text)).toEqual({
      frontmatter: 'fields: title, assignees, dueDate\ndisplay: list',
      query: 'assignee = currentUser()',
    });
  });

  it('returns empty frontmatter if no frontmatter is present', () => {
    const text = 'assignee = currentUser()';

    expect(parseQueryTextWithFrontmatter(text)).toEqual({
      frontmatter: '',
      query: 'assignee = currentUser()',
    });
  });
});

describe('parse', () => {
  beforeEach(() => {
    gon.current_username = 'root';
    document.body.dataset.projectFullPath = 'gitlab-org/gitlab';
  });

  afterEach(() => {
    delete document.body.dataset.projectFullPath;
  });

  it('parses a simple query correctly', async () => {
    expect(await parse('assignee = currentUser()')).toMatchInlineSnapshot(`
{
  "config": {
    "display": "list",
  },
  "fields": [
    {
      "_internal": {
        "Static": "Title",
      },
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title",
    },
  ],
  "mode": "standard",
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  project(fullPath: "gitlab-org/gitlab") {
    workItems(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
      nodes {
        id
        iid
        title
        titleHtml
        webUrl
        reference
        state
        title
      }
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      count
    }
  }
}
",
  "source": "WorkItems",
  "variables": {
    "after": {
      "type": "String",
      "value": null,
    },
    "before": {
      "type": "String",
      "value": null,
    },
    "limit": {
      "type": "Int",
      "value": null,
    },
  },
}
`);
  });

  it('parses a query with frontmatter correctly', async () => {
    expect(
      await parse(`
---
fields: title, assignees, dueDate
display: table
---
assignee = currentUser()`),
    ).toMatchInlineSnapshot(`
{
  "config": {
    "display": "table",
    "fields": "title, assignees, dueDate",
  },
  "fields": [
    {
      "_internal": {
        "Static": "Title",
      },
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title",
    },
    {
      "_internal": {
        "Static": {
          "AliasedField": [
            "Assignee",
            "assignees",
          ],
        },
      },
      "field": "assignees",
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees",
    },
    {
      "_internal": {
        "Static": {
          "AliasedField": [
            "Due",
            "dueDate",
          ],
        },
      },
      "field": "dueDate",
      "key": "dueDate",
      "label": "Due date",
      "name": "dueDate",
    },
  ],
  "mode": "standard",
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  project(fullPath: "gitlab-org/gitlab") {
    workItems(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
      nodes {
        id
        iid
        title
        titleHtml
        webUrl
        reference
        state
        title
        widgets {
          ... on WorkItemWidgetAssignees {
            type
            assignees {
              nodes {
                id
                avatarUrl
                username
                name
                webUrl
              }
            }
          }
        }
        widgets {
          ... on WorkItemWidgetStartAndDueDate {
            type
            dueDate
          }
        }
      }
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      count
    }
  }
}
",
  "source": "WorkItems",
  "variables": {
    "after": {
      "type": "String",
      "value": null,
    },
    "before": {
      "type": "String",
      "value": null,
    },
    "limit": {
      "type": "Int",
      "value": null,
    },
  },
}
`);
  });

  it('parses a YAML based query correctly', async () => {
    expect(
      await parse(`
fields: title, assignees, dueDate
display: table
limit: 20
query: assignee = currentUser()
`),
    ).toMatchInlineSnapshot(`
{
  "config": {
    "display": "table",
    "fields": "title, assignees, dueDate",
    "limit": 20,
  },
  "fields": [
    {
      "_internal": {
        "Static": "Title",
      },
      "field": "title",
      "key": "title",
      "label": "Title",
      "name": "title",
    },
    {
      "_internal": {
        "Static": {
          "AliasedField": [
            "Assignee",
            "assignees",
          ],
        },
      },
      "field": "assignees",
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees",
    },
    {
      "_internal": {
        "Static": {
          "AliasedField": [
            "Due",
            "dueDate",
          ],
        },
      },
      "field": "dueDate",
      "key": "dueDate",
      "label": "Due date",
      "name": "dueDate",
    },
  ],
  "mode": "standard",
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  project(fullPath: "gitlab-org/gitlab") {
    workItems(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
      nodes {
        id
        iid
        title
        titleHtml
        webUrl
        reference
        state
        title
        widgets {
          ... on WorkItemWidgetAssignees {
            type
            assignees {
              nodes {
                id
                avatarUrl
                username
                name
                webUrl
              }
            }
          }
        }
        widgets {
          ... on WorkItemWidgetStartAndDueDate {
            type
            dueDate
          }
        }
      }
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      count
    }
  }
}
",
  "source": "WorkItems",
  "variables": {
    "after": {
      "type": "String",
      "value": null,
    },
    "before": {
      "type": "String",
      "value": null,
    },
    "limit": {
      "type": "Int",
      "value": null,
    },
  },
}
`);
  });
});

describe('parseYAMLConfig', () => {
  it('parses the frontmatter and returns an object', () => {
    const frontmatter = 'fields: title, assignees, dueDate\ndisplay: list';

    expect(parseYAMLConfig(frontmatter)).toEqual({
      fields: 'title, assignees, dueDate',
      display: 'list',
    });
  });
});

describe('parseQuery', () => {
  beforeEach(() => {
    gon.current_username = 'foobar';
  });

  afterEach(() => {
    delete gon.current_username;
  });

  it('parses a simple query by converting it to GraphQL', async () => {
    const query = 'assignee = currentUser()';
    const config = { fields: MOCK_FIELDS, limit: 50, project: 'gitlab-org/gitlab' };
    const { query: result } = await parseQuery(query, config);

    expect(prettify(result)).toMatchInlineSnapshot(`
"query GLQL($before: String, $after: String, $limit: Int) {
  project(fullPath: "gitlab-org/gitlab") {
    workItems(
      assigneeUsernames: "foobar"
      before: $before
      after: $after
      first: $limit
    ) {
      nodes {
        id
        iid
        title
        titleHtml
        webUrl
        reference
        state
        title
        author {
          id
          avatarUrl
          username
          name
          webUrl
        }
        state
        descriptionHtml
      }
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      count
    }
  }
}"
`);
  });

  it('handles complex queries with multiple conditions', async () => {
    const query = 'assignee = currentUser() AND label IN ("bug", "feature")';
    const config = { fields: MOCK_FIELDS, limit: 50, project: 'gitlab-org/gitlab' };
    const { query: result } = await parseQuery(query, config);

    expect(prettify(result)).toMatchInlineSnapshot(`
"query GLQL($before: String, $after: String, $limit: Int) {
  project(fullPath: "gitlab-org/gitlab") {
    workItems(
      assigneeUsernames: "foobar"
      or: {labelNames: ["bug", "feature"]}
      before: $before
      after: $after
      first: $limit
    ) {
      nodes {
        id
        iid
        title
        titleHtml
        webUrl
        reference
        state
        title
        author {
          id
          avatarUrl
          username
          name
          webUrl
        }
        state
        descriptionHtml
      }
      pageInfo {
        startCursor
        endCursor
        hasNextPage
        hasPreviousPage
      }
      count
    }
  }
}"
`);
  });

  it('throws an error for invalid queries', async () => {
    const query = 'invalid query syntax';
    const config = { fields: MOCK_FIELDS, limit: 100 };

    await expect(parseQuery(query, config)).rejects.toThrow(
      'Error: Unexpected `query syntax`, expected operator (one of IN, =, !=, >, or <)',
    );
  });
});

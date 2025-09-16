import { parse as parseGraphQL, print } from 'graphql';
import {
  parseQueryTextWithFrontmatter,
  parse,
  parseQuery,
  parseYAMLConfig,
} from '~/glql/core/parser';

const prettify = (query) => print(parseGraphQL(query));

const MOCK_FIELDS = 'title, author, state, description';

beforeEach(() => {
  gon.features = {
    glqlTypescript: true,
  };
});

afterEach(() => {
  gon.features = {};
});

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
  });

  it('parses a simple query correctly', async () => {
    expect(await parse('assignee = currentUser()')).toMatchInlineSnapshot(`
{
  "config": {
    "display": "list",
    "fields": "title",
  },
  "fields": [
    {
      "key": "title",
      "label": "Title",
      "name": "title",
    },
  ],
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  issues(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
    nodes {
      id
      iid
      title
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
",
  "variables": {
    "after": {
      "type": "String",
      "value": undefined,
    },
    "before": {
      "type": "String",
      "value": undefined,
    },
    "limit": {
      "type": "Int",
      "value": undefined,
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
      "key": "title",
      "label": "Title",
      "name": "title",
    },
    {
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees",
    },
    {
      "key": "dueDate",
      "label": "Due date",
      "name": "dueDate",
    },
  ],
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  issues(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
    nodes {
      id
      iid
      title
      webUrl
      reference
      state
      title
      assignees {
        nodes {
          id
          avatarUrl
          username
          name
          webUrl
        }
      }
      dueDate
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
",
  "variables": {
    "after": {
      "type": "String",
      "value": undefined,
    },
    "before": {
      "type": "String",
      "value": undefined,
    },
    "limit": {
      "type": "Int",
      "value": undefined,
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
      "key": "title",
      "label": "Title",
      "name": "title",
    },
    {
      "key": "assignees",
      "label": "Assignees",
      "name": "assignees",
    },
    {
      "key": "dueDate",
      "label": "Due date",
      "name": "dueDate",
    },
  ],
  "query": "query GLQL($before: String, $after: String, $limit: Int) {
  issues(assigneeUsernames: "root", before: $before, after: $after, first: $limit) {
    nodes {
      id
      iid
      title
      webUrl
      reference
      state
      title
      assignees {
        nodes {
          id
          avatarUrl
          username
          name
          webUrl
        }
      }
      dueDate
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
",
  "variables": {
    "after": {
      "type": "String",
      "value": undefined,
    },
    "before": {
      "type": "String",
      "value": undefined,
    },
    "limit": {
      "type": "Int",
      "value": undefined,
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

  it('returns default fields if none are provided', () => {
    const frontmatter = 'display: list';

    expect(parseYAMLConfig(frontmatter)).toEqual({
      fields: 'title',
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
    const config = { fields: MOCK_FIELDS, limit: 50 };
    const { query: result } = await parseQuery(query, config);

    expect(prettify(result)).toMatchInlineSnapshot(`
"query GLQL($before: String, $after: String, $limit: Int) {
  issues(
    assigneeUsernames: "foobar"
    before: $before
    after: $after
    first: $limit
  ) {
    nodes {
      id
      iid
      title
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
    issues(
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
      'Error: Expected valid operator near `query syntax`',
    );
  });
});

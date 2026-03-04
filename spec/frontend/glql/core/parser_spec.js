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

  describe('aggregation feature flag handling', () => {
    const groupBy = "timeSegment(1w) on mergedAt as 'Date merged'";
    const aggregate = "count as 'Total count'";
    const query = 'type = MergeRequest and merged >= 2025-05-01 and merged <= 2025-05-30';
    const config = { fields: MOCK_FIELDS, groupBy, aggregate };

    describe('when aggregation is disabled', () => {
      beforeEach(() => {
        gon.features = {
          ...gon.features,
          glqlAggregation: false,
        };
      });

      it('compiles without aggregation context when flag is disabled', async () => {
        const result = await parseQuery(query, config);

        expect(result.query).toBeDefined();
        const fieldKeys = result.fields.map((f) => f.key);
        expect(fieldKeys).not.toContain('mergedAt');
        expect(fieldKeys).not.toContain('count');
      });

      it('preserves other config properties when omitting aggregation config', async () => {
        const configWithExtra = {
          ...config,
          limit: 100,
          display: 'table',
          customProperty: 'value',
        };

        const result = await parseQuery(query, configWithExtra);

        expect(result.query).toBeDefined();
        // Verify that non-aggregation config is preserved in the returned config
        expect(result.config.limit).toBe(100);
        expect(result.config.display).toBe('table');
        expect(result.config.customProperty).toBe('value');
        expect(result.config.fields).toBe(MOCK_FIELDS);
      });
    });

    describe('when aggregation is enabled', () => {
      beforeEach(() => {
        gon.features = {
          ...gon.features,
          glqlAggregation: true,
        };
      });

      it('compiles aggregation query successfully with dimensions and metrics', async () => {
        const result = await parseQuery(query, config);

        expect(result.query).toMatchInlineSnapshot(`
"query GLQL {
  from_2025_05_01_to_2025_05_05: mergeRequests(mergedAfter: "2025-05-01 00:00", mergedBefore: "2025-05-05 00:00", first: 0) {
    count
  }
  from_2025_05_05_to_2025_05_12: mergeRequests(mergedAfter: "2025-05-05 00:00", mergedBefore: "2025-05-12 00:00", first: 0) {
    count
  }
  from_2025_05_12_to_2025_05_19: mergeRequests(mergedAfter: "2025-05-12 00:00", mergedBefore: "2025-05-19 00:00", first: 0) {
    count
  }
  from_2025_05_19_to_2025_05_26: mergeRequests(mergedAfter: "2025-05-19 00:00", mergedBefore: "2025-05-26 00:00", first: 0) {
    count
  }
  from_2025_05_26_to_2025_05_30: mergeRequests(mergedAfter: "2025-05-26 00:00", mergedBefore: "2025-05-30 23:59", first: 0) {
    count
  }
}
"
`);
        expect(result.fields).toMatchInlineSnapshot(`
[
  {
    "key": "mergedAt",
    "label": "Date merged",
    "name": "mergedAt",
  },
  {
    "key": "count",
    "label": "Total count",
    "name": "count",
  },
]
`);
      });
    });

    describe('when aggregation feature flag is undefined', () => {
      beforeEach(() => {
        gon.features = {
          ...gon.features,
        };
        delete gon.features.glqlAggregation;
      });

      it('treats undefined feature flag as disabled', async () => {
        const result = await parseQuery(query, config);

        expect(result.query).toBeDefined();
        const fieldKeys = result.fields.map((f) => f.key);
        expect(fieldKeys).not.toContain('mergedAt');
        expect(fieldKeys).not.toContain('count');
      });
    });
  });

  it('throws an error for invalid queries', async () => {
    const query = 'invalid query syntax';
    const config = { fields: MOCK_FIELDS, limit: 100 };

    await expect(parseQuery(query, config)).rejects.toThrow(
      'Error: Unexpected `query syntax`, expected operator (one of IN, =, !=, >, or <)',
    );
  });
});

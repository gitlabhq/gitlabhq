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
  "aggregate": [],
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
  "groupBy": [],
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
  "aggregate": [],
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
  "groupBy": [],
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
  "aggregate": [],
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
  "groupBy": [],
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

      it('omits groupBy and aggregate from config passed to glql.compile', async () => {
        const result = await parseQuery(query, config);

        // The returned result should still have empty arrays for groupBy and aggregate
        // since the feature flag is disabled
        expect(result.groupBy).toEqual([]);
        expect(result.aggregate).toEqual([]);
      });

      it('preserves other config properties when omitting aggregation config', async () => {
        const configWithExtra = {
          ...config,
          limit: 100,
          display: 'table',
          customProperty: 'value',
        };

        const result = await parseQuery(query, configWithExtra);

        // Verify that non-aggregation config is preserved in the returned config
        expect(result.config.limit).toBe(100);
        expect(result.config.display).toBe('table');
        expect(result.config.customProperty).toBe('value');
        expect(result.config.fields).toBe(MOCK_FIELDS);

        // But aggregation properties should not be processed
        expect(result.groupBy).toEqual([]);
        expect(result.aggregate).toEqual([]);
      });
    });

    describe('when aggregation is enabled', () => {
      beforeEach(() => {
        gon.features = {
          ...gon.features,
          glqlAggregation: true,
        };
      });

      it('includes groupBy and aggregate in config passed to glql.compile', async () => {
        const result = await parseQuery(query, config);

        // When feature flag is enabled, aggregation should be processed
        expect(result.groupBy).toMatchInlineSnapshot(`
[
  Dimension {
    "field": {
      "key": "mergedAt",
      "label": "Date merged",
      "name": "mergedAt",
    },
    "fn": Time {
      "quantity": 1,
      "timeSegmentType": "fromStartOfUnit",
      "type": "time",
      "unit": "w",
    },
  },
]
`);
        expect(result.aggregate).toMatchInlineSnapshot(`
[
  {
    "key": "count",
    "label": "Total count",
    "name": "count",
  },
]
`);
      });

      it('parses the aggregation config correctly', async () => {
        const result = await parseQuery(query, config);

        expect(result.groupBy).toHaveLength(1);
        expect(result.aggregate).toHaveLength(1);
        expect(result.groupBy[0].field.key).toBe('mergedAt');
        expect(result.groupBy[0].field.label).toBe('Date merged');
        expect(result.aggregate[0].key).toBe('count');
        expect(result.aggregate[0].label).toBe('Total count');
      });
    });

    describe('when aggregation feature flag is undefined', () => {
      beforeEach(() => {
        gon.features = {
          ...gon.features,
        };
        delete gon.features.glqlAggregation;
      });

      it('treats undefined feature flag as disabled and omits aggregation config', async () => {
        const result = await parseQuery(query, config);

        // When feature flag is undefined, it should be treated as disabled
        expect(result.groupBy).toEqual([]);
        expect(result.aggregate).toEqual([]);
      });
    });
  });

  describe('when aggregation is enabled', () => {
    beforeEach(() => {
      gon.features = {
        ...gon.features,
        glqlAggregation: true,
      };
    });
    const groupBy = "timeSegment(1w) on mergedAt as 'Date merged'";
    const aggregate = "count as 'Total count'";

    it('parses the aggregation config', async () => {
      const query = await parseQuery(
        'type = MergeRequest and merged >= 2025-05-01 and merged <= 2025-05-30',
        { fields: MOCK_FIELDS, groupBy, aggregate },
      );
      expect(query.groupBy).toMatchInlineSnapshot(`
[
  Dimension {
    "field": {
      "key": "mergedAt",
      "label": "Date merged",
      "name": "mergedAt",
    },
    "fn": Time {
      "quantity": 1,
      "timeSegmentType": "fromStartOfUnit",
      "type": "time",
      "unit": "w",
    },
  },
]
`);
      expect(query.aggregate).toMatchInlineSnapshot(`
[
  {
    "key": "count",
    "label": "Total count",
    "name": "count",
  },
]
`);
    });
  });

  it('throws an error for invalid queries', async () => {
    const query = 'invalid query syntax';
    const config = { fields: MOCK_FIELDS, limit: 100 };

    await expect(parseQuery(query, config)).rejects.toThrow(
      'Error: Expected valid operator near `query syntax`',
    );
  });
});

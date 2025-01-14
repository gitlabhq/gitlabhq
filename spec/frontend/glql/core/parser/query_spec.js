import { parse, print } from 'graphql';
import { parseQuery } from '~/glql/core/parser/query';
import { MOCK_FIELDS } from '../../mock_data';

const prettify = (query) => print(parse(query));

describe('GLQL Query Parser', () => {
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
      const result = await parseQuery(query, config);

      expect(prettify(result)).toMatchInlineSnapshot(`
"query GLQL {
  issues(assigneeUsernames: "foobar", first: 50) {
    nodes {
      id
      iid
      title
      webUrl
      reference
      state
      author {
        id
        avatarUrl
        username
        name
        webUrl
      }
      description
    }
    pageInfo {
      startCursor
      endCursor
      hasNextPage
      hasPreviousPage
    }
  }
}
"
`);
    });

    it('handles complex queries with multiple conditions', async () => {
      const query = 'assignee = currentUser() AND label IN ("bug", "feature")';
      const config = { fields: MOCK_FIELDS, limit: 50 };
      const result = await parseQuery(query, config);

      expect(prettify(result)).toMatchInlineSnapshot(`
"query GLQL {
  issues(
    assigneeUsernames: "foobar"
    or: {labelNames: ["bug", "feature"]}
    first: 50
  ) {
    nodes {
      id
      iid
      title
      webUrl
      reference
      state
      author {
        id
        avatarUrl
        username
        name
        webUrl
      }
      description
    }
    pageInfo {
      startCursor
      endCursor
      hasNextPage
      hasPreviousPage
    }
  }
}
"
`);
    });

    it('throws an error for invalid queries', async () => {
      const query = 'invalid query syntax';
      const config = { fields: MOCK_FIELDS, limit: 100 };

      await expect(parseQuery(query, config)).rejects.toThrow(
        'Unexpected `query syntax`, expected operator (one of IN, =, !=, >, or <)',
      );
    });
  });
});

import { print } from 'graphql/language/printer';
import Executor from '~/glql/core/executor';
import createDefaultClient from '~/lib/graphql';
import { MOCK_ISSUES } from '../mock_data';

jest.mock('~/lib/graphql', () => jest.fn());

const MOCK_QUERY_RESPONSE = { project: { issues: MOCK_ISSUES } };

describe('Executor', () => {
  let executor;
  let queryFn;

  const mockQueryResponse = (response) => {
    queryFn = jest.fn().mockResolvedValue({ data: response });
    createDefaultClient.mockReturnValue({
      query: queryFn,
    });
  };

  beforeEach(async () => {
    gon.current_username = 'foobar';
    mockQueryResponse(MOCK_QUERY_RESPONSE);
    executor = await new Executor().init();
  });

  afterEach(() => {
    delete gon.current_username;
  });

  it('executes a query using GLQL compiler', async () => {
    const { data, config } = await executor.compile('assignee = currentUser()').execute();

    expect(print(queryFn.mock.calls[0][0].query)).toMatchInlineSnapshot(`
"{
  issues(assigneeUsernames: "foobar", first: 100) {
    nodes {
      id
      iid
      title
      webUrl
      reference
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
"
`);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);

    // default config options
    expect(config).toEqual({ display: 'list', fields: ['title'] });
  });

  it('includes fields provided in config, each field included just once', async () => {
    const { data, config } = await executor
      .compile(
        `
---
fields: title, id, title, iid, author, title
---
assignee = currentUser()
`,
      )
      .execute();

    expect(print(queryFn.mock.calls[0][0].query)).toMatchInlineSnapshot(`
"{
  issues(assigneeUsernames: "foobar", first: 100) {
    nodes {
      id
      iid
      title
      webUrl
      reference
      author {
        id
        avatarUrl
        username
        name
        webUrl
      }
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
"
`);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);
    expect(config).toEqual({ display: 'list', fields: ['title', 'id', 'iid', 'author'] });
  });

  it('correctly reads limit and display options from config', async () => {
    const { data, config } = await executor
      .compile(
        `
---
limit: 5
display: list
---
assignee = currentUser()
`,
      )
      .execute();

    expect(print(queryFn.mock.calls[0][0].query)).toMatchInlineSnapshot(`
"{
  issues(assigneeUsernames: "foobar", first: 5) {
    nodes {
      id
      iid
      title
      webUrl
      reference
    }
    pageInfo {
      endCursor
      hasNextPage
    }
  }
}
"
`);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);
    expect(config).toEqual({
      display: 'list',
      fields: ['title'],
      limit: 5,
    });
  });
});

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

  it('executes a query using a graphql client', async () => {
    const data = await executor.execute(`
      {
        issues(assigneeUsernames: "foobar", first: 100) {
          nodes { id iid title webUrl reference state type }
          pageInfo { endCursor hasNextPage }
        }
      }
      `);

    expect(data).toEqual(MOCK_QUERY_RESPONSE);
  });
});

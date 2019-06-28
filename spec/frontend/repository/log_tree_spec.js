import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { normalizeData, resolveCommit, fetchLogsTree } from '~/repository/log_tree';

const mockData = [
  {
    commit: {
      id: '123',
      message: 'testing message',
      committed_date: '2019-01-01',
    },
    commit_path: `https://test.com`,
    file_name: 'index.js',
    type: 'blob',
  },
];

describe('normalizeData', () => {
  it('normalizes data into LogTreeCommit object', () => {
    expect(normalizeData(mockData)).toEqual([
      {
        sha: '123',
        message: 'testing message',
        committedDate: '2019-01-01',
        commitPath: 'https://test.com',
        fileName: 'index.js',
        type: 'blob',
        __typename: 'LogTreeCommit',
      },
    ]);
  });
});

describe('resolveCommit', () => {
  it('calls resolve when commit found', () => {
    const resolver = {
      entry: { name: 'index.js', type: 'blob' },
      resolve: jest.fn(),
    };
    const commits = [{ fileName: 'index.js', type: 'blob' }];

    resolveCommit(commits, resolver);

    expect(resolver.resolve).toHaveBeenCalledWith({ fileName: 'index.js', type: 'blob' });
  });
});

describe('fetchLogsTree', () => {
  let mock;
  let client;
  let resolver;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    mock.onGet(/(.*)/).reply(200, mockData, {});

    jest.spyOn(axios, 'get');

    global.gon = { gitlab_url: 'https://test.com' };

    client = {
      readQuery: () => ({
        projectPath: 'gitlab-org/gitlab-ce',
        ref: 'master',
        commits: [],
      }),
      writeQuery: jest.fn(),
    };

    resolver = {
      entry: { name: 'index.js', type: 'blob' },
      resolve: jest.fn(),
    };
  });

  afterEach(() => {
    mock.restore();
  });

  it('calls axios get', () =>
    fetchLogsTree(client, '', '0', resolver).then(() => {
      expect(axios.get).toHaveBeenCalledWith(
        'https://test.com/gitlab-org/gitlab-ce/refs/master/logs_tree',
        { params: { format: 'json', offset: '0' } },
      );
    }));

  it('calls axios get once', () =>
    Promise.all([
      fetchLogsTree(client, '', '0', resolver),
      fetchLogsTree(client, '', '0', resolver),
    ]).then(() => {
      expect(axios.get.mock.calls.length).toEqual(1);
    }));

  it('calls entry resolver', () =>
    fetchLogsTree(client, '', '0', resolver).then(() => {
      expect(resolver.resolve).toHaveBeenCalledWith({
        __typename: 'LogTreeCommit',
        commitPath: 'https://test.com',
        committedDate: '2019-01-01',
        fileName: 'index.js',
        message: 'testing message',
        sha: '123',
        type: 'blob',
      });
    }));

  it('writes query to client', () =>
    fetchLogsTree(client, '', '0', resolver).then(() => {
      expect(client.writeQuery).toHaveBeenCalledWith({
        query: expect.anything(),
        data: {
          commits: [
            {
              __typename: 'LogTreeCommit',
              commitPath: 'https://test.com',
              committedDate: '2019-01-01',
              fileName: 'index.js',
              message: 'testing message',
              sha: '123',
              type: 'blob',
            },
          ],
        },
      });
    }));
});

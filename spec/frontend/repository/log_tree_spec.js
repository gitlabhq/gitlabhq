import MockAdapter from 'axios-mock-adapter';
import { createMockClient } from 'helpers/mock_apollo_helper';
import axios from '~/lib/utils/axios_utils';
import { resolveCommit, fetchLogsTree } from '~/repository/log_tree';
import commitsQuery from '~/repository/queries/commits.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import refQuery from '~/repository/queries/ref.query.graphql';

const mockData = [
  {
    commit: {
      id: '123',
      message: 'testing message',
      committed_date: '2019-01-01',
    },
    commit_path: `https://test.com`,
    commit_title_html: 'commit title',
    file_name: 'index.js',
    type: 'blob',
  },
];

describe('resolveCommit', () => {
  it('calls resolve when commit found', () => {
    const resolver = {
      entry: { name: 'index.js', type: 'blob' },
      resolve: jest.fn(),
    };
    const commits = [
      { fileName: 'index.js', filePath: '/index.js', type: 'blob' },
      { fileName: 'index.js', filePath: '/app/assets/index.js', type: 'blob' },
    ];

    resolveCommit(commits, '', resolver);

    expect(resolver.resolve).toHaveBeenCalledWith({
      fileName: 'index.js',
      filePath: '/index.js',
      type: 'blob',
    });
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

    global.gon = { relative_url_root: '' };

    resolver = {
      entry: { name: 'index.js', type: 'blob' },
      resolve: jest.fn(),
    };

    client = createMockClient();
    client.writeQuery({ query: projectPathQuery, data: { projectPath: 'gitlab-org/gitlab-foss' } });
    client.writeQuery({ query: refQuery, data: { ref: 'main', escapedRef: 'main' } });
    client.writeQuery({ query: commitsQuery, data: { commits: [] } });
  });

  afterEach(() => {
    mock.restore();
  });

  it('persists the offset for a given page if offset is larger than maximum offset', async () => {
    await fetchLogsTree(client, 'path', '1000', resolver, 900).then(() => {});

    await fetchLogsTree(client, 'path', '1100', resolver, 1200).then(() => {
      expect(axios.get).toHaveBeenCalledWith('/gitlab-org/gitlab-foss/-/refs/main/logs_tree/path', {
        params: { format: 'json', offset: 975 },
      });
    });
  });

  it('does not call axios get if offset is larger than the maximum offset', () =>
    fetchLogsTree(client, '', '1000', resolver, 900).then(() => {
      expect(axios.get).not.toHaveBeenCalled();
    }));

  it('calls axios get', () =>
    fetchLogsTree(client, '', '0', resolver).then(() => {
      expect(axios.get).toHaveBeenCalledWith('/gitlab-org/gitlab-foss/-/refs/main/logs_tree/', {
        params: { format: 'json', offset: '0' },
      });
    }));

  it('calls axios get once', () =>
    Promise.all([
      fetchLogsTree(client, '', '0', resolver),
      fetchLogsTree(client, '', '0', resolver),
    ]).then(() => {
      expect(axios.get.mock.calls.length).toEqual(1);
    }));

  it('calls axios for each path', () =>
    Promise.all([
      fetchLogsTree(client, '', '0', resolver),
      fetchLogsTree(client, '/test', '0', resolver),
    ]).then(() => {
      expect(axios.get.mock.calls.length).toEqual(2);
    }));

  it('calls entry resolver', () =>
    fetchLogsTree(client, '', '0', resolver).then(() => {
      expect(resolver.resolve).toHaveBeenCalledWith(
        expect.objectContaining({
          __typename: 'LogTreeCommit',
          commitPath: 'https://test.com',
          committedDate: '2019-01-01',
          fileName: 'index.js',
          filePath: '/index.js',
          message: 'testing message',
          sha: '123',
          type: 'blob',
        }),
      );
    }));

  it('writes query to client', async () => {
    await fetchLogsTree(client, '', '0', resolver);
    expect(client.readQuery({ query: commitsQuery })).toEqual({
      commits: [
        expect.objectContaining({
          commitPath: 'https://test.com',
          committedDate: '2019-01-01',
          fileName: 'index.js',
          filePath: '/index.js',
          message: 'testing message',
          sha: '123',
          titleHtml: 'commit title',
          type: 'blob',
        }),
      ],
    });
  });
});

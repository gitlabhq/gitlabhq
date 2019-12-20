import { normalizeData } from '~/repository/utils/commit';

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
    expect(normalizeData(mockData, '')).toEqual([
      {
        sha: '123',
        message: 'testing message',
        committedDate: '2019-01-01',
        commitPath: 'https://test.com',
        fileName: 'index.js',
        filePath: '/index.js',
        type: 'blob',
        __typename: 'LogTreeCommit',
      },
    ]);
  });
});

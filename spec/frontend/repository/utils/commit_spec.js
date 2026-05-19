import { normalizeData } from '~/repository/utils/commit';

const mockData = [
  {
    commit: {
      id: '123',
      message: 'testing message',
      committed_date: '2019-01-01',
    },
    commit_path: `https://test.com`,
    commit_title_html: 'testing message',
    file_name: 'index.js',
    lock_label: 'Locked',
  },
];

describe('normalizeData', () => {
  it('normalizes data into LogTreeCommit object', () => {
    expect(normalizeData(mockData, '/')).toEqual([
      {
        sha: '123',
        message: 'testing message',
        committedDate: '2019-01-01',
        commitPath: 'https://test.com',
        fileName: 'index.js',
        filePath: '/index.js',
        lockLabel: 'Locked',
        titleHtml: 'testing message',
        __typename: 'LogTreeCommit',
      },
    ]);
  });

  it('normalizes data into LogTreeCommit object with no lockLabel', () => {
    const mock = [...mockData];
    delete mock[0].lock_label;

    expect(normalizeData(mock, '/')).toEqual([
      {
        sha: '123',
        message: 'testing message',
        committedDate: '2019-01-01',
        commitPath: 'https://test.com',
        fileName: 'index.js',
        filePath: '/index.js',
        lockLabel: false,
        titleHtml: 'testing message',
        __typename: 'LogTreeCommit',
      },
    ]);
  });
});

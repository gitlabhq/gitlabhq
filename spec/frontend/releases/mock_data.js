export const pageInfoHeadersWithoutPagination = {
  'X-NEXT-PAGE': '',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '19',
  'X-TOTAL-PAGES': '1',
};

export const pageInfoHeadersWithPagination = {
  'X-NEXT-PAGE': '2',
  'X-PAGE': '1',
  'X-PER-PAGE': '20',
  'X-PREV-PAGE': '',
  'X-TOTAL': '21',
  'X-TOTAL-PAGES': '2',
};

export const graphqlReleasesResponse = {
  data: {
    project: {
      releases: {
        count: 39,
        nodes: [
          {
            name: 'Release 1.0',
            tagName: 'v5.10',
            tagPath: '/root/release-test/-/tags/v5.10',
            descriptionHtml:
              '<p data-sourcepos="1:1-1:24" dir="auto">This is version <strong>1.0</strong>!</p>',
            releasedAt: '2020-08-21T20:15:18Z',
            upcomingRelease: false,
            assets: {
              count: 7,
              sources: {
                nodes: [
                  {
                    format: 'zip',
                    url:
                      'http://0.0.0.0:3000/root/release-test/-/archive/v5.10/release-test-v5.10.zip',
                  },
                  {
                    format: 'tar.gz',
                    url:
                      'http://0.0.0.0:3000/root/release-test/-/archive/v5.10/release-test-v5.10.tar.gz',
                  },
                  {
                    format: 'tar.bz2',
                    url:
                      'http://0.0.0.0:3000/root/release-test/-/archive/v5.10/release-test-v5.10.tar.bz2',
                  },
                  {
                    format: 'tar',
                    url:
                      'http://0.0.0.0:3000/root/release-test/-/archive/v5.10/release-test-v5.10.tar',
                  },
                ],
              },
              links: {
                nodes: [
                  {
                    id: 'gid://gitlab/Releases::Link/69',
                    name: 'An example link',
                    url: 'https://example.com/link',
                    directAssetUrl:
                      'http://0.0.0.0:3000/root/release-test/-/releases/v5.32/permanent/path/to/runbook',
                    linkType: 'OTHER',
                    external: true,
                  },
                  {
                    id: 'gid://gitlab/Releases::Link/68',
                    name: 'An example package link',
                    url: 'https://example.com/package',
                    directAssetUrl: 'https://example.com/package',
                    linkType: 'PACKAGE',
                    external: true,
                  },
                  {
                    id: 'gid://gitlab/Releases::Link/67',
                    name: 'An example image',
                    url: 'https://example.com/image',
                    directAssetUrl: 'https://example.com/image',
                    linkType: 'IMAGE',
                    external: true,
                  },
                ],
              },
            },
            evidences: {
              nodes: [
                {
                  filepath:
                    'http://0.0.0.0:3000/root/release-test/-/releases/v5.10/evidences/34.json',
                  collectedAt: '2020-08-21T20:15:19Z',
                  sha: '22bde8e8b93d870a29ddc339287a1fbb598f45d1396d',
                },
              ],
            },
            links: {
              editUrl: 'http://0.0.0.0:3000/root/release-test/-/releases/v5.10/edit',
              issuesUrl: null,
              mergeRequestsUrl: null,
              selfUrl: 'http://0.0.0.0:3000/root/release-test/-/releases/v5.10',
            },
            commit: {
              sha: '92e7ea2ee4496fe0d00ff69830ba0564d3d1e5a7',
              webUrl:
                'http://0.0.0.0:3000/root/release-test/-/commit/92e7ea2ee4496fe0d00ff69830ba0564d3d1e5a7',
              title: 'Testing a change.',
            },
            author: {
              webUrl: 'http://0.0.0.0:3000/root',
              avatarUrl: '/uploads/-/system/user/avatar/1/avatar.png',
              username: 'root',
            },
            milestones: {
              nodes: [
                {
                  id: 'gid://gitlab/Milestone/60',
                  title: '12.4',
                  description: '',
                  webPath: '/root/release-test/-/milestones/2',
                  stats: {
                    totalIssuesCount: 0,
                    closedIssuesCount: 0,
                  },
                },
                {
                  id: 'gid://gitlab/Milestone/59',
                  title: '12.3',
                  description: 'Milestone 12.3',
                  webPath: '/root/release-test/-/milestones/1',
                  stats: {
                    totalIssuesCount: 2,
                    closedIssuesCount: 1,
                  },
                },
              ],
            },
          },
        ],
        pageInfo: {
          startCursor:
            'eyJpZCI6IjQ0IiwicmVsZWFzZWRfYXQiOiIyMDMwLTAzLTE1IDA4OjAwOjAwLjAwMDAwMDAwMCBVVEMifQ',
          hasPreviousPage: false,
          hasNextPage: true,
          endCursor:
            'eyJpZCI6IjMiLCJyZWxlYXNlZF9hdCI6IjIwMjAtMDctMDkgMjA6MTE6MzMuODA0OTYxMDAwIFVUQyJ9',
        },
      },
    },
  },
};

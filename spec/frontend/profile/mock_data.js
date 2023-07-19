export const userCalendarResponse = {
  '2022-11-18': 13,
  '2022-11-19': 21,
  '2022-11-20': 14,
  '2022-11-21': 15,
  '2022-11-22': 20,
  '2022-11-23': 21,
  '2022-11-24': 15,
  '2022-11-25': 14,
  '2022-11-26': 16,
  '2022-11-27': 13,
  '2022-11-28': 4,
  '2022-11-29': 1,
  '2022-11-30': 1,
  '2022-12-13': 1,
  '2023-01-10': 3,
  '2023-01-11': 2,
  '2023-01-20': 1,
  '2023-02-02': 1,
  '2023-02-06': 2,
  '2023-02-07': 2,
};

export const MOCK_SNIPPETS_EMPTY_STATE = 'illustrations/empty-state/empty-snippets-md.svg';
export const MOCK_NEW_SNIPPET_PATH = '/-/snippets/new';

export const MOCK_USER = {
  id: '1',
  avatarUrl: 'https://www.gravatar.com/avatar/test',
  name: 'Test User',
  username: 'test',
};

const getMockSnippet = (id) => {
  return {
    id: `gid://gitlab/PersonalSnippet/${id}`,
    title: `Test snippet ${id}`,
    visibilityLevel: 'public',
    webUrl: `http://gitlab.com/-/snippets/${id}`,
    createdAt: new Date(),
    updatedAt: new Date(),
    blobs: {
      nodes: [
        {
          name: 'test.txt',
        },
      ],
    },
    notes: {
      nodes: [
        {
          id: 'git://gitlab/Note/1',
        },
      ],
    },
  };
};

const MOCK_PAGE_INFO = {
  startCursor: 'asdfqwer',
  endCursor: 'reqwfdsa',
  __typename: 'PageInfo',
};

const getMockSnippetRes = (hasPagination) => {
  return {
    data: {
      user: {
        ...MOCK_USER,
        snippets: {
          pageInfo: {
            ...MOCK_PAGE_INFO,
            hasNextPage: hasPagination,
            hasPreviousPage: hasPagination,
          },
          nodes: [getMockSnippet(1), getMockSnippet(2)],
        },
      },
    },
  };
};

export const MOCK_SNIPPET = getMockSnippet(1);
export const MOCK_USER_SNIPPETS_RES = getMockSnippetRes(false);
export const MOCK_USER_SNIPPETS_PAGINATION_RES = getMockSnippetRes(true);
export const MOCK_USER_SNIPPETS_EMPTY_RES = {
  data: {
    user: {
      ...MOCK_USER,
      snippets: {
        pageInfo: {
          endCursor: null,
          startCursor: null,
        },
        nodes: [],
      },
    },
  },
};

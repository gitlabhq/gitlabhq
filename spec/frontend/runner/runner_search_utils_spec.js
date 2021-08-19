import { RUNNER_PAGE_SIZE } from '~/runner/constants';
import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from '~/runner/runner_search_utils';

describe('search_params.js', () => {
  const examples = [
    {
      name: 'a default query',
      urlQuery: '',
      search: { filters: [], pagination: { page: 1 }, sort: 'CREATED_DESC' },
      graphqlVariables: { sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'a single status',
      urlQuery: '?status[]=ACTIVE',
      search: {
        filters: [{ type: 'status', value: { data: 'ACTIVE', operator: '=' } }],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { status: 'ACTIVE', sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'a single term text search',
      urlQuery: '?search=something',
      search: {
        filters: [
          {
            type: 'filtered-search-term',
            value: { data: 'something' },
          },
        ],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { search: 'something', sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'a two terms text search',
      urlQuery: '?search=something+else',
      search: {
        filters: [
          {
            type: 'filtered-search-term',
            value: { data: 'something' },
          },
          {
            type: 'filtered-search-term',
            value: { data: 'else' },
          },
        ],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { search: 'something else', sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'single instance type',
      urlQuery: '?runner_type[]=INSTANCE_TYPE',
      search: {
        filters: [{ type: 'runner_type', value: { data: 'INSTANCE_TYPE', operator: '=' } }],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { type: 'INSTANCE_TYPE', sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'multiple runner status',
      urlQuery: '?status[]=ACTIVE&status[]=PAUSED',
      search: {
        filters: [
          { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
          { type: 'status', value: { data: 'PAUSED', operator: '=' } },
        ],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { status: 'ACTIVE', sort: 'CREATED_DESC', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'multiple status, a single instance type and a non default sort',
      urlQuery: '?status[]=ACTIVE&runner_type[]=INSTANCE_TYPE&sort=CREATED_ASC',
      search: {
        filters: [
          { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
          { type: 'runner_type', value: { data: 'INSTANCE_TYPE', operator: '=' } },
        ],
        pagination: { page: 1 },
        sort: 'CREATED_ASC',
      },
      graphqlVariables: {
        status: 'ACTIVE',
        type: 'INSTANCE_TYPE',
        sort: 'CREATED_ASC',
        first: RUNNER_PAGE_SIZE,
      },
    },
    {
      name: 'a tag',
      urlQuery: '?tag[]=tag-1',
      search: {
        filters: [{ type: 'tag', value: { data: 'tag-1', operator: '=' } }],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: {
        tagList: ['tag-1'],
        first: 20,
        sort: 'CREATED_DESC',
      },
    },
    {
      name: 'two tags',
      urlQuery: '?tag[]=tag-1&tag[]=tag-2',
      search: {
        filters: [
          { type: 'tag', value: { data: 'tag-1', operator: '=' } },
          { type: 'tag', value: { data: 'tag-2', operator: '=' } },
        ],
        pagination: { page: 1 },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: {
        tagList: ['tag-1', 'tag-2'],
        first: 20,
        sort: 'CREATED_DESC',
      },
    },
    {
      name: 'the next page',
      urlQuery: '?page=2&after=AFTER_CURSOR',
      search: { filters: [], pagination: { page: 2, after: 'AFTER_CURSOR' }, sort: 'CREATED_DESC' },
      graphqlVariables: { sort: 'CREATED_DESC', after: 'AFTER_CURSOR', first: RUNNER_PAGE_SIZE },
    },
    {
      name: 'the previous page',
      urlQuery: '?page=2&before=BEFORE_CURSOR',
      search: {
        filters: [],
        pagination: { page: 2, before: 'BEFORE_CURSOR' },
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { sort: 'CREATED_DESC', before: 'BEFORE_CURSOR', last: RUNNER_PAGE_SIZE },
    },
    {
      name: 'the next page filtered by a status, an instance type, tags and a non default sort',
      urlQuery:
        '?status[]=ACTIVE&runner_type[]=INSTANCE_TYPE&tag[]=tag-1&tag[]=tag-2&sort=CREATED_ASC&page=2&after=AFTER_CURSOR',
      search: {
        filters: [
          { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
          { type: 'runner_type', value: { data: 'INSTANCE_TYPE', operator: '=' } },
          { type: 'tag', value: { data: 'tag-1', operator: '=' } },
          { type: 'tag', value: { data: 'tag-2', operator: '=' } },
        ],
        pagination: { page: 2, after: 'AFTER_CURSOR' },
        sort: 'CREATED_ASC',
      },
      graphqlVariables: {
        status: 'ACTIVE',
        type: 'INSTANCE_TYPE',
        tagList: ['tag-1', 'tag-2'],
        sort: 'CREATED_ASC',
        after: 'AFTER_CURSOR',
        first: RUNNER_PAGE_SIZE,
      },
    },
  ];

  describe('fromUrlQueryToSearch', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a search object`, () => {
        expect(fromUrlQueryToSearch(urlQuery)).toEqual(search);
      });
    });

    it('When search params appear as array, they are concatenated', () => {
      expect(fromUrlQueryToSearch('?search[]=my&search[]=text').filters).toEqual([
        { type: 'filtered-search-term', value: { data: 'my' } },
        { type: 'filtered-search-term', value: { data: 'text' } },
      ]);
    });

    it('When a page cannot be parsed as a number, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=NONSENSE&after=AFTER_CURSOR').pagination).toEqual({
        page: 1,
      });
    });

    it('When a page is less than 1, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=0&after=AFTER_CURSOR').pagination).toEqual({
        page: 1,
      });
    });

    it('When a page with no cursor is given, it defaults to `1`', () => {
      expect(fromUrlQueryToSearch('?page=2').pagination).toEqual({
        page: 1,
      });
    });
  });

  describe('fromSearchToUrl', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a url`, () => {
        expect(fromSearchToUrl(search)).toEqual(`http://test.host/${urlQuery}`);
      });
    });

    it.each([
      'http://test.host/?status[]=ACTIVE',
      'http://test.host/?runner_type[]=INSTANCE_TYPE',
      'http://test.host/?search=my_text',
    ])('When a filter is removed, it is removed from the URL', (initalUrl) => {
      const search = { filters: [], sort: 'CREATED_DESC' };
      const expectedUrl = `http://test.host/`;

      expect(fromSearchToUrl(search, initalUrl)).toEqual(expectedUrl);
    });

    it('When unrelated search parameter is present, it does not get removed', () => {
      const initialUrl = `http://test.host/?unrelated=UNRELATED&status[]=ACTIVE`;
      const search = { filters: [], sort: 'CREATED_DESC' };
      const expectedUrl = `http://test.host/?unrelated=UNRELATED`;

      expect(fromSearchToUrl(search, initialUrl)).toEqual(expectedUrl);
    });
  });

  describe('fromSearchToVariables', () => {
    examples.forEach(({ name, graphqlVariables, search }) => {
      it(`Converts ${name} to a GraphQL query variables object`, () => {
        expect(fromSearchToVariables(search)).toEqual(graphqlVariables);
      });
    });

    it('When a search param is empty, it gets removed', () => {
      expect(
        fromSearchToVariables({
          filters: [
            {
              type: 'filtered-search-term',
              value: { data: '' },
            },
          ],
        }),
      ).toMatchObject({
        search: '',
      });

      expect(
        fromSearchToVariables({
          filters: [
            {
              type: 'filtered-search-term',
              value: { data: 'something' },
            },
            {
              type: 'filtered-search-term',
              value: { data: '' },
            },
          ],
        }),
      ).toMatchObject({
        search: 'something',
      });
    });
  });
});

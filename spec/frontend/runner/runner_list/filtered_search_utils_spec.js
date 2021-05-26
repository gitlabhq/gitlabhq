import {
  fromUrlQueryToSearch,
  fromSearchToUrl,
  fromSearchToVariables,
} from '~/runner/runner_list/filtered_search_utils';

describe('search_params.js', () => {
  const examples = [
    {
      name: 'a default query',
      urlQuery: '',
      search: { filters: [], sort: 'CREATED_DESC' },
      graphqlVariables: { sort: 'CREATED_DESC' },
    },
    {
      name: 'a single status',
      urlQuery: '?status[]=ACTIVE',
      search: {
        filters: [{ type: 'status', value: { data: 'ACTIVE', operator: '=' } }],
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { status: 'ACTIVE', sort: 'CREATED_DESC' },
    },
    {
      name: 'single instance type',
      urlQuery: '?runner_type[]=INSTANCE_TYPE',
      search: {
        filters: [{ type: 'runner_type', value: { data: 'INSTANCE_TYPE', operator: '=' } }],
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { type: 'INSTANCE_TYPE', sort: 'CREATED_DESC' },
    },
    {
      name: 'multiple runner status',
      urlQuery: '?status[]=ACTIVE&status[]=PAUSED',
      search: {
        filters: [
          { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
          { type: 'status', value: { data: 'PAUSED', operator: '=' } },
        ],
        sort: 'CREATED_DESC',
      },
      graphqlVariables: { status: 'ACTIVE', sort: 'CREATED_DESC' },
    },
    {
      name: 'multiple status, a single instance type and a non default sort',
      urlQuery: '?status[]=ACTIVE&runner_type[]=INSTANCE_TYPE&sort=CREATED_ASC',
      search: {
        filters: [
          { type: 'status', value: { data: 'ACTIVE', operator: '=' } },
          { type: 'runner_type', value: { data: 'INSTANCE_TYPE', operator: '=' } },
        ],
        sort: 'CREATED_ASC',
      },
      graphqlVariables: { status: 'ACTIVE', type: 'INSTANCE_TYPE', sort: 'CREATED_ASC' },
    },
  ];

  describe('fromUrlQueryToSearch', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a search object`, () => {
        expect(fromUrlQueryToSearch(urlQuery)).toEqual(search);
      });
    });
  });

  describe('fromSearchToUrl', () => {
    examples.forEach(({ name, urlQuery, search }) => {
      it(`Converts ${name} to a url`, () => {
        expect(fromSearchToUrl(search)).toEqual(`http://test.host/${urlQuery}`);
      });
    });

    it('When a filtered search parameter is already present, it gets removed', () => {
      const initialUrl = `http://test.host/?status[]=ACTIVE`;
      const search = { filters: [], sort: 'CREATED_DESC' };
      const expectedUrl = `http://test.host/`;

      expect(fromSearchToUrl(search, initialUrl)).toEqual(expectedUrl);
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
  });
});

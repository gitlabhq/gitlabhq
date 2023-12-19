import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import DataSourceFactory, {
  defaultSorter,
  customSorter,
  createDataSource,
} from '~/content_editor/services/data_source_factory';
import {
  MOCK_MEMBERS,
  MOCK_COMMANDS,
  MOCK_EPICS,
  MOCK_ISSUES,
  MOCK_LABELS,
  MOCK_MILESTONES,
  MOCK_SNIPPETS,
  MOCK_VULNERABILITIES,
  MOCK_MERGE_REQUESTS,
  MOCK_ASSIGNEES,
  MOCK_REVIEWERS,
} from './autocomplete_mock_data';

jest.mock('~/emoji');

describe('defaultSorter', () => {
  it('returns items as is if query is empty', () => {
    const items = [{ name: 'abc' }, { name: 'bcd' }, { name: 'cde' }];
    const sorter = defaultSorter(['name']);
    expect(sorter(items, '')).toEqual(items);
  });

  it('sorts items based on query match', () => {
    const items = [{ name: 'abc' }, { name: 'bcd' }, { name: 'cde' }];
    const sorter = defaultSorter(['name']);
    expect(sorter(items, 'b')).toEqual([{ name: 'bcd' }, { name: 'abc' }, { name: 'cde' }]);
  });

  it('sorts items based on query match in multiple fields', () => {
    const items = [
      { name: 'wabc', description: 'xyz' },
      { name: 'bcd', description: 'wxy' },
      { name: 'cde', description: 'vwx' },
    ];
    const sorter = defaultSorter(['name', 'description']);
    expect(sorter(items, 'w')).toEqual([
      { name: 'wabc', description: 'xyz' },
      { name: 'bcd', description: 'wxy' },
      { name: 'cde', description: 'vwx' },
    ]);
  });
});

describe('customSorter', () => {
  it('sorts items based on custom sorter function', () => {
    const items = [3, 1, 2];
    const sorter = customSorter((a, b) => a - b);
    expect(sorter(items)).toEqual([1, 2, 3]);
  });
});

describe('createDataSource', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it('fetches data from source and filters based on query', async () => {
    const data = [
      { name: 'abc', description: 'xyz' },
      { name: 'bcd', description: 'wxy' },
      { name: 'cde', description: 'vwx' },
    ];
    mock.onGet('/source').reply(200, data);

    const dataSource = createDataSource({
      source: '/source',
      searchFields: ['name', 'description'],
    });

    const results = await dataSource.search('b');
    expect(results).toEqual([
      { name: 'bcd', description: 'wxy' },
      { name: 'abc', description: 'xyz' },
    ]);
  });

  it('handles source fetch errors', async () => {
    mock.onGet('/source').reply(500);

    const dataSource = createDataSource({
      source: '/source',
      searchFields: ['name', 'description'],
      sorter: (items) => items,
    });

    const results = await dataSource.search('b');
    expect(results).toEqual([]);
  });
});

describe('DataSourceFactory', () => {
  let mock;
  let autocompleteHelper;
  let dateNowOld;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    const dataSourceUrls = {
      members: '/members',
      issues: '/issues',
      snippets: '/snippets',
      labels: '/labels',
      epics: '/epics',
      milestones: '/milestones',
      mergeRequests: '/mergeRequests',
      vulnerabilities: '/vulnerabilities',
      commands: '/commands',
    };

    mock.onGet('/members').reply(200, MOCK_MEMBERS);
    mock.onGet('/issues').reply(200, MOCK_ISSUES);
    mock.onGet('/snippets').reply(200, MOCK_SNIPPETS);
    mock.onGet('/labels').reply(200, MOCK_LABELS);
    mock.onGet('/epics').reply(200, MOCK_EPICS);
    mock.onGet('/milestones').reply(200, MOCK_MILESTONES);
    mock.onGet('/mergeRequests').reply(200, MOCK_MERGE_REQUESTS);
    mock.onGet('/vulnerabilities').reply(200, MOCK_VULNERABILITIES);
    mock.onGet('/commands').reply(200, MOCK_COMMANDS);

    const sidebarMediator = {
      store: {
        assignees: MOCK_ASSIGNEES,
        reviewers: MOCK_REVIEWERS,
      },
    };

    autocompleteHelper = new DataSourceFactory({
      dataSourceUrls,
      sidebarMediator,
    });

    dateNowOld = Date.now();

    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2023-11-14').getTime());
  });

  afterEach(() => {
    mock.restore();

    jest.spyOn(Date, 'now').mockImplementation(() => dateNowOld);
  });

  it.each`
    referenceType      | query
    ${'user'}          | ${'r'}
    ${'issue'}         | ${'q'}
    ${'snippet'}       | ${'s'}
    ${'label'}         | ${'c'}
    ${'epic'}          | ${'n'}
    ${'milestone'}     | ${'16'}
    ${'merge_request'} | ${'n'}
    ${'vulnerability'} | ${'cross'}
    ${'command'}       | ${'re'}
  `(
    'for reference type "$referenceType", searches for "$query" correctly',
    async ({ referenceType, query }) => {
      const dataSource = autocompleteHelper.getDataSource(referenceType);
      const results = await dataSource.search(query);

      expect(
        results.map(({ title, name, username }) => username || name || title),
      ).toMatchSnapshot();
    },
  );

  it.each`
    referenceType | command
    ${'label'}    | ${'/label'}
    ${'label'}    | ${'/unlabel'}
    ${'label'}    | ${'/relabel'}
    ${'user'}     | ${'/assign'}
    ${'user'}     | ${'/reassign'}
    ${'user'}     | ${'/unassign'}
    ${'user'}     | ${'/assign_reviewer'}
    ${'user'}     | ${'/unassign_reviewer'}
    ${'user'}     | ${'/reassign_reviewer'}
  `(
    'filters items based on command "$command" for reference type "$referenceType" and command',
    async ({ referenceType, command }) => {
      const dataSource = autocompleteHelper.getDataSource(referenceType, { command });
      const results = await dataSource.search();

      expect(
        results.map(({ username, name, title }) => username || name || title),
      ).toMatchSnapshot();
    },
  );
});

import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import AutocompleteHelper, {
  defaultSorter,
  customSorter,
  createDataSource,
} from '~/content_editor/services/autocomplete_helper';
import { HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { EMOJI_THUMBS_UP } from '~/emoji/constants';
import {
  MOCK_MEMBERS,
  MOCK_COMMANDS,
  MOCK_EPICS,
  MOCK_ISSUES,
  MOCK_LABELS,
  MOCK_MILESTONES,
  MOCK_ITERATIONS,
  MOCK_SNIPPETS,
  MOCK_VULNERABILITIES,
  MOCK_MERGE_REQUESTS,
  MOCK_ASSIGNEES,
  MOCK_REVIEWERS,
  MOCK_WIKIS,
  MOCK_NEW_MEMBERS,
} from './autocomplete_mock_data';

jest.mock('~/emoji', () => ({
  initEmojiMap: () => jest.fn(),
  getAllEmoji: () => [{ name: 'thumbsup' }],
}));

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

  describe('on fetch success', () => {
    const dataSourceParams = {
      source: '/source',
      searchFields: ['name', 'description'],
    };

    beforeEach(() => {
      const data = [
        { name: 'abc', description: 'xyz' },
        { name: 'bcd', description: 'wxy' },
        { name: 'cde', description: 'vwx' },
      ];
      mock.onGet('/source').reply(HTTP_STATUS_OK, data);
    });

    it('fetches data from source and filters based on query', async () => {
      const dataSource = createDataSource(dataSourceParams);

      const results = await dataSource.search('b');
      expect(results).toEqual([
        { name: 'bcd', description: 'wxy' },
        { name: 'abc', description: 'xyz' },
      ]);
    });

    describe('if filterOnBackend: true', () => {
      it('fetches data from source, passing a `search` param', async () => {
        const dataSource = createDataSource({
          ...dataSourceParams,
          filterOnBackend: true,
        });

        const results = await dataSource.search('bcd');
        expect(mock.history.get[0].params).toEqual({ search: 'bcd' });

        // results are still filtered out on frontend, on top of backend filtering
        expect(results).toEqual([{ name: 'bcd', description: 'wxy' }]);
      });
    });
  });

  it('handles source fetch errors', async () => {
    mock.onGet('/source').reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);

    const dataSource = createDataSource({
      source: '/source',
      searchFields: ['name', 'description'],
      sorter: (items) => items,
    });

    const results = await dataSource.search('b');
    expect(results).toEqual([]);
  });
});

describe('AutocompleteHelper', () => {
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
      iterations: '/iterations',
      mergeRequests: '/mergeRequests',
      vulnerabilities: '/vulnerabilities',
      commands: '/commands',
      wikis: '/wikis',
    };

    mock.onGet('/members').reply(HTTP_STATUS_OK, MOCK_MEMBERS);
    mock.onGet('/issues').reply(HTTP_STATUS_OK, MOCK_ISSUES);
    mock.onGet('/snippets').reply(HTTP_STATUS_OK, MOCK_SNIPPETS);
    mock.onGet('/labels').reply(HTTP_STATUS_OK, MOCK_LABELS);
    mock.onGet('/epics').reply(HTTP_STATUS_OK, MOCK_EPICS);
    mock.onGet('/milestones').reply(HTTP_STATUS_OK, MOCK_MILESTONES);
    mock.onGet('/iterations').reply(HTTP_STATUS_OK, MOCK_ITERATIONS);
    mock.onGet('/mergeRequests').reply(HTTP_STATUS_OK, MOCK_MERGE_REQUESTS);
    mock.onGet('/vulnerabilities').reply(HTTP_STATUS_OK, MOCK_VULNERABILITIES);
    mock.onGet('/commands').reply(HTTP_STATUS_OK, MOCK_COMMANDS);
    mock.onGet('/wikis').reply(HTTP_STATUS_OK, MOCK_WIKIS);

    mock.onGet('/new/members').reply(HTTP_STATUS_OK, MOCK_NEW_MEMBERS);

    const sidebarMediator = {
      store: {
        assignees: MOCK_ASSIGNEES,
        reviewers: MOCK_REVIEWERS,
      },
    };

    autocompleteHelper = new AutocompleteHelper({
      dataSourceUrls,
      sidebarMediator,
    });

    dateNowOld = Date.now();

    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2023-11-14').getTime());
  });

  afterEach(() => {
    mock.restore();

    delete gl.GfmAutoComplete;

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
    ${'iteration'}     | ${'27'}
    ${'merge_request'} | ${'n'}
    ${'vulnerability'} | ${'cross'}
    ${'command'}       | ${'re'}
    ${'wiki'}          | ${'ho'}
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

  it('filters items correctly for the second time, when the first command was different', async () => {
    let dataSource = autocompleteHelper.getDataSource('label', { command: '/label' });
    let results = await dataSource.search();

    // all labels listed for the first command
    expect(results.map(({ title }) => title)).toEqual([
      'Bronce',
      'Contour',
      'Corolla',
      'Cygsync',
      'Frontier',
      'Grand Am',
      'Onesync',
      'Phone',
      'Pynefunc',
      'Trinix',
      'Trounswood',
      'group::knowledge',
      'scoped label',
      'type::one',
      'type::two',
    ]);

    dataSource = autocompleteHelper.getDataSource('label', { command: '/unlabel' });
    results = await dataSource.search();

    // only set labels listed for the second command
    expect(results.map(({ title }) => title)).toEqual(['Amsche', 'Brioffe', 'Bryncefunc', 'Ghost']);
  });

  it('loads default datasources if not passed', () => {
    gl.GfmAutoComplete = {
      dataSources: {
        members: '/gitlab-org/gitlab-test/-/autocomplete_sources/members',
      },
    };
    autocompleteHelper = new AutocompleteHelper({});

    expect(autocompleteHelper.dataSourceUrls.members).toBe(
      '/gitlab-org/gitlab-test/-/autocomplete_sources/members',
    );
  });

  it("loads emoji if dataSources doesn't exist", async () => {
    autocompleteHelper = new AutocompleteHelper({});

    const dataSource = autocompleteHelper.getDataSource('emoji');
    const results = await dataSource.search('');

    expect(results).toEqual([{ emoji: { name: EMOJI_THUMBS_UP }, fieldValue: EMOJI_THUMBS_UP }]);
  });

  it('updates dataSourcesUrl correctly', () => {
    const newDataSources = {
      members: '/new/members',
      issues: '/new/issues',
      snippets: '/new/snippets',
      labels: '/new/labels',
      epics: '/new/epics',
      milestones: '/new/milestones',
      iterations: '/new/iterations',
      mergeRequests: '/new/mergeRequests',
      vulnerabilities: '/new/vulnerabilities',
      commands: '/new/commands',
      wikis: '/new/wikis',
    };

    autocompleteHelper.updateDataSources(newDataSources);
    expect(autocompleteHelper.dataSourceUrls).toEqual(newDataSources);
  });

  it('returns expected results before and after updating data sources', async () => {
    // Retrieve the initial data source and search for 'user'
    let dataSource = autocompleteHelper.getDataSource('user');
    let results = await dataSource.search('');

    expect(results.map(({ username }) => username)).toMatchSnapshot();

    // Update the data sources
    const newDataSources = {
      members: '/new/members',
    };
    autocompleteHelper.updateDataSources(newDataSources);

    // Retrieve the updated data source and search for 'user'
    dataSource = autocompleteHelper.getDataSource('user');
    results = await dataSource.search('');

    expect(results.map(({ username }) => username)).toMatchSnapshot();
  });
});

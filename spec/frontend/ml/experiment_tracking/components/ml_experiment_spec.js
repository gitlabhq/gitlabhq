import { GlAlert, GlPagination, GlTable, GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MlExperiment from '~/ml/experiment_tracking/components/ml_experiment.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlHelpers from '~/lib/utils/url_utility';

describe('MlExperiment', () => {
  let wrapper;

  const createWrapper = (
    candidates = [],
    metricNames = [],
    paramNames = [],
    pagination = { page: 1, isLastPage: false, per_page: 2, totalItems: 0 },
  ) => {
    wrapper = mountExtended(MlExperiment, {
      provide: { candidates, metricNames, paramNames, pagination },
    });
  };

  const defaultPagination = { page: 1, isLastPage: false, per_page: 2, totalItems: 5 };

  const candidates = [
    {
      rmse: 1,
      l1_ratio: 0.4,
      details: 'link_to_candidate1',
      artifact: 'link_to_artifact',
      name: 'aCandidate',
      created_at: '2023-01-05T14:07:02.975Z',
      user: { username: 'root', path: '/root' },
    },
    {
      auc: 0.3,
      l1_ratio: 0.5,
      details: 'link_to_candidate2',
      created_at: '2023-01-05T14:07:02.975Z',
      name: null,
      user: null,
    },
    {
      auc: 0.3,
      l1_ratio: 0.5,
      details: 'link_to_candidate3',
      created_at: '2023-01-05T14:07:02.975Z',
      name: null,
      user: null,
    },
    {
      auc: 0.3,
      l1_ratio: 0.5,
      details: 'link_to_candidate4',
      created_at: '2023-01-05T14:07:02.975Z',
      name: null,
      user: null,
    },
    {
      auc: 0.3,
      l1_ratio: 0.5,
      details: 'link_to_candidate5',
      created_at: '2023-01-05T14:07:02.975Z',
      name: null,
      user: null,
    },
  ];

  const createWrapperWithCandidates = (pagination = defaultPagination) => {
    createWrapper(candidates, ['rmse', 'auc', 'mae'], ['l1_ratio'], pagination);
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPagination = () => wrapper.findComponent(GlPagination);
  const findEmptyState = () => wrapper.findByText('No candidates to display');
  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findTable = () => wrapper.findComponent(GlTable);
  const findTableHeaders = () => findTable().findAll('th');
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findNthTableRow = (idx) => findTableRows().at(idx);
  const findColumnInRow = (row, col) => findNthTableRow(row).findAll('td').at(col);
  const hrefInRowAndColumn = (row, col) =>
    findColumnInRow(row, col).findComponent(GlLink).attributes().href;

  it('shows incubation warning', () => {
    createWrapper();

    expect(findAlert().exists()).toBe(true);
  });

  describe('default inputs', () => {
    beforeEach(async () => {
      createWrapper();

      await nextTick();
    });

    it('shows empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });

    it('there are no columns', () => {
      expect(findTable().findAll('th')).toHaveLength(0);
    });

    it('initializes sorting correctly', () => {
      expect(findRegistrySearch().props('sorting')).toMatchObject({
        orderBy: 'created_at',
        sort: 'desc',
      });
    });

    it('initializes filters correctly', () => {
      expect(findRegistrySearch().props('filters')).toMatchObject([{ value: { data: '' } }]);
    });
  });

  describe('generateLink', () => {
    it('generates the correct url', () => {
      setWindowLocation(
        'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc&page=1',
      );

      createWrapperWithCandidates();

      expect(findPagination().props('linkGen')(2)).toBe(
        'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc&page=2',
      );
    });

    it('generates the correct url when no name', () => {
      setWindowLocation('https://blah.com/?orderBy=auc&orderByType=metric&sort=asc');

      createWrapperWithCandidates();

      expect(findPagination().props('linkGen')(2)).toBe(
        'https://blah.com/?orderBy=auc&orderByType=metric&sort=asc&page=2',
      );
    });
  });

  describe('Search', () => {
    it('shows search box', () => {
      createWrapper();

      expect(findRegistrySearch().exists()).toBe(true);
    });

    it('metrics are added as options for sorting', () => {
      createWrapper([], ['bar']);

      const labels = findRegistrySearch()
        .props('sortableFields')
        .map((e) => e.orderBy);
      expect(labels).toContain('metric.bar');
    });

    it('sets the component filters based on the querystring', () => {
      setWindowLocation('https://blah?name=A&orderBy=B&sort=C');

      createWrapper();

      expect(findRegistrySearch().props('filters')).toMatchObject([{ value: { data: 'A' } }]);
    });

    it('sets the component sort based on the querystring', () => {
      setWindowLocation('https://blah?name=A&orderBy=B&sort=C');

      createWrapper();

      expect(findRegistrySearch().props('sorting')).toMatchObject({ orderBy: 'B', sort: 'c' });
    });

    it('sets the component sort based on the querystring, when order by is a metric', () => {
      setWindowLocation('https://blah?name=A&orderBy=B&sort=C&orderByType=metric');

      createWrapper();

      expect(findRegistrySearch().props('sorting')).toMatchObject({
        orderBy: 'metric.B',
        sort: 'c',
      });
    });

    describe('Search submit', () => {
      beforeEach(() => {
        setWindowLocation('https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc');
        jest.spyOn(urlHelpers, 'visitUrl').mockImplementation(() => {});

        createWrapper();
      });

      it('On submit, reloads to correct page', () => {
        findRegistrySearch().vm.$emit('filter:submit');

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc&page=1',
        );
      });

      it('On sorting changed, reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { orderBy: 'created_at' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=created_at&orderByType=column&sort=asc&page=1',
        );
      });

      it('On sorting changed and is metric, reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { orderBy: 'metric.auc' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=auc&orderByType=metric&sort=asc&page=1',
        );
      });

      it('On direction changed, reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { sort: 'desc' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=desc&page=1',
        );
      });
    });
  });

  describe('with candidates', () => {
    describe('Pagination behaviour', () => {
      beforeEach(() => {
        createWrapperWithCandidates();
      });

      it('should show', () => {
        expect(findPagination().exists()).toBe(true);
      });

      it('should get the page number from the URL', () => {
        createWrapperWithCandidates({ ...defaultPagination, page: 2 });

        expect(findPagination().props().value).toBe(2);
      });

      it('should not have a prevPage if the page is 1', () => {
        expect(findPagination().props().prevPage).toBe(null);
      });

      it('should set the prevPage to 1 if the page is 2', () => {
        createWrapperWithCandidates({ ...defaultPagination, page: 2 });

        expect(findPagination().props().prevPage).toBe(1);
      });

      it('should not have a nextPage if isLastPage is true', async () => {
        createWrapperWithCandidates({ ...defaultPagination, isLastPage: true });

        expect(findPagination().props().nextPage).toBe(null);
      });

      it('should set the nextPage to 2 if the page is 1', () => {
        expect(findPagination().props().nextPage).toBe(2);
      });
    });
  });

  describe('Candidate table', () => {
    const firstCandidateIndex = 0;
    const secondCandidateIndex = 1;
    const firstCandidate = candidates[firstCandidateIndex];

    beforeEach(() => {
      createWrapperWithCandidates();
    });

    it('renders all rows', () => {
      expect(findTableRows()).toHaveLength(candidates.length);
    });

    it('sets the correct columns in the table', () => {
      const expectedColumnNames = [
        'Name',
        'Created at',
        'User',
        'L1 Ratio',
        'Rmse',
        'Auc',
        'Mae',
        '',
        '',
      ];

      expect(findTableHeaders().wrappers.map((h) => h.text())).toEqual(expectedColumnNames);
    });

    describe('Artifact column', () => {
      const artifactColumnIndex = -1;

      it('shows the a link to the artifact', () => {
        expect(hrefInRowAndColumn(firstCandidateIndex, artifactColumnIndex)).toBe(
          firstCandidate.artifact,
        );
      });

      it('shows empty state when no artifact', () => {
        expect(findColumnInRow(secondCandidateIndex, artifactColumnIndex).text()).toBe('-');
      });
    });

    describe('User column', () => {
      const userColumn = 2;

      it('creates a link to the user', () => {
        const column = findColumnInRow(firstCandidateIndex, userColumn).findComponent(GlLink);

        expect(column.attributes().href).toBe(firstCandidate.user.path);
        expect(column.text()).toBe(`@${firstCandidate.user.username}`);
      });

      it('when there is no user shows empty state', () => {
        createWrapperWithCandidates();

        expect(findColumnInRow(secondCandidateIndex, userColumn).text()).toBe('-');
      });
    });

    describe('Candidate name column', () => {
      const nameColumnIndex = 0;

      it('Sets the name', () => {
        expect(findColumnInRow(firstCandidateIndex, nameColumnIndex).text()).toBe(
          firstCandidate.name,
        );
      });

      it('when there is no user shows nothing', () => {
        expect(findColumnInRow(secondCandidateIndex, nameColumnIndex).text()).toBe('');
      });
    });

    describe('Detail column', () => {
      const detailColumn = -2;

      it('is a link to details', () => {
        expect(hrefInRowAndColumn(firstCandidateIndex, detailColumn)).toBe(firstCandidate.details);
      });
    });
  });
});

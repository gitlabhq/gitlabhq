import { GlTableLite, GlLink, GlEmptyState } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import CandidateList from '~/ml/experiment_tracking/components/candidate_list.vue';
import Pagination from '~/ml/experiment_tracking/components/pagination.vue';
import RegistrySearch from '~/vue_shared/components/registry/registry_search.vue';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as urlHelpers from '~/lib/utils/url_utility';
import {
  MOCK_START_CURSOR,
  MOCK_PAGE_INFO,
  MOCK_CANDIDATES,
} from '../routes/experiments/show/mock_data';

describe('CandidateList', () => {
  let wrapper;

  const createWrapper = (
    candidates = [],
    metricNames = [],
    paramNames = [],
    pageInfo = MOCK_PAGE_INFO,
    emptyStateSvgPath = 'path',
    // eslint-disable-next-line max-params
  ) => {
    wrapper = mount(CandidateList, {
      propsData: { candidates, metricNames, paramNames, pageInfo, emptyStateSvgPath },
      stubs: { GlLink, GlTableLite },
    });
  };

  const createWrapperWithCandidates = (pageInfo = MOCK_PAGE_INFO) => {
    createWrapper(MOCK_CANDIDATES, ['rmse', 'auc', 'mae'], ['l1_ratio'], pageInfo);
  };

  const findPagination = () => wrapper.findComponent(Pagination);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findRegistrySearch = () => wrapper.findComponent(RegistrySearch);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findTableHeaders = () => findTable().findAll('th');
  const findTableRows = () => findTable().findAll('tbody > tr');
  const findNthTableRow = (idx) => findTableRows().at(idx);
  const findColumnInRow = (row, col) => findNthTableRow(row).findAll('td').at(col);

  const hrefInRowAndColumn = (row, col) =>
    findColumnInRow(row, col).findComponent(GlLink).attributes().href;
  const linkTextInRowAndColumn = (row, col) =>
    findColumnInRow(row, col).findComponent(GlLink).text();

  describe('default inputs', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });

    it('does not show table', () => {
      expect(findTable().exists()).toBe(false);
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

  describe('search', () => {
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

    describe('search submit', () => {
      beforeEach(() => {
        setWindowLocation('https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc');
        jest.spyOn(urlHelpers, 'visitUrl').mockImplementation(() => {});

        createWrapper();
      });

      it('on submit, resets the cursor and reloads to correct page', () => {
        findRegistrySearch().vm.$emit('filter:submit');

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=asc',
        );
      });

      it('on sorting changed, resets cursor and reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { orderBy: 'created_at' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=created_at&orderByType=column&sort=asc',
        );
      });

      it('on sorting changed and is metric, resets cursor and reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { orderBy: 'metric.auc' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=auc&orderByType=metric&sort=asc',
        );
      });

      it('on direction changed, reloads to correct page', () => {
        findRegistrySearch().vm.$emit('sorting:changed', { sort: 'desc' });

        expect(urlHelpers.visitUrl).toHaveBeenCalledTimes(1);
        expect(urlHelpers.visitUrl).toHaveBeenCalledWith(
          'https://blah.com/?name=query&orderBy=name&orderByType=column&sort=desc',
        );
      });
    });
  });

  describe('pagination behaviour', () => {
    beforeEach(() => {
      createWrapperWithCandidates();
    });

    it('should show', () => {
      expect(findPagination().exists()).toBe(true);
    });

    it('passes pagination to pagination component', () => {
      createWrapperWithCandidates();

      expect(findPagination().props('startCursor')).toBe(MOCK_START_CURSOR);
    });
  });

  describe('candidate table', () => {
    const firstCandidateIndex = 0;
    const secondCandidateIndex = 1;
    const firstCandidate = MOCK_CANDIDATES[firstCandidateIndex];

    beforeEach(() => {
      createWrapperWithCandidates();
    });

    it('renders all rows', () => {
      expect(findTableRows()).toHaveLength(MOCK_CANDIDATES.length);
    });

    it('sets the correct columns in the table', () => {
      const expectedColumnNames = [
        'Name',
        'Created at',
        'Author',
        'L1 Ratio',
        'Rmse',
        'Auc',
        'Mae',
        'CI Job',
        'Artifacts',
      ];

      expect(findTableHeaders().wrappers.map((h) => h.text())).toEqual(expectedColumnNames);
    });

    describe('artifact column', () => {
      const artifactColumnIndex = 8;

      it('shows the a link to the artifact', () => {
        expect(hrefInRowAndColumn(firstCandidateIndex, artifactColumnIndex)).toBe(
          firstCandidate.artifact,
        );
      });

      it('shows empty state when no artifact', () => {
        expect(findColumnInRow(secondCandidateIndex, artifactColumnIndex).text()).toBe(
          'No artifacts',
        );
      });
    });

    describe('CI Job column', () => {
      const jobColumnIndex = 7;

      it('has a link to the job', () => {
        expect(hrefInRowAndColumn(firstCandidateIndex, jobColumnIndex)).toBe(
          firstCandidate.ci_job.path,
        );
      });

      it('shows the name of the job', () => {
        expect(linkTextInRowAndColumn(firstCandidateIndex, jobColumnIndex)).toBe(
          firstCandidate.ci_job.name,
        );
      });

      it('shows empty state when there is no job', () => {
        expect(findColumnInRow(secondCandidateIndex, jobColumnIndex).text()).toBe('-');
      });
    });

    describe('user column', () => {
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

    describe('candidate name column', () => {
      const nameColumnIndex = 0;

      it('sets the name', () => {
        expect(findColumnInRow(firstCandidateIndex, nameColumnIndex).text()).toBe(
          firstCandidate.name,
        );
      });

      it('when there is no user shows nothing', () => {
        expect(findColumnInRow(secondCandidateIndex, nameColumnIndex).text()).toBe('No name');
      });
    });
  });
});

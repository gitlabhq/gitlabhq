import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import { queryToObject, objectToQuery } from '~/lib/utils/url_utility';
import setWindowLocation from 'helpers/set_window_location_helper';
import AbuseReportsApp from '~/admin/abuse_reports/components/app.vue';
import AbuseReportsFilteredSearchBar from '~/admin/abuse_reports/components/abuse_reports_filtered_search_bar.vue';
import AbuseReportRow from '~/admin/abuse_reports/components/abuse_report_row.vue';
import { mockAbuseReports } from '../mock_data';

describe('AbuseReportsApp', () => {
  let wrapper;

  const findFilteredSearchBar = () => wrapper.findComponent(AbuseReportsFilteredSearchBar);
  const findEmptyState = () => wrapper.findComponent(EmptyResult);
  const findAbuseReportRows = () => wrapper.findAllComponents(AbuseReportRow);
  const findPagination = () => wrapper.findComponent(GlPagination);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(AbuseReportsApp, {
      propsData: {
        abuseReports: mockAbuseReports,
        pagination: { currentPage: 1, perPage: 20, totalItems: mockAbuseReports.length },
        ...props,
      },
    });
  };

  it('renders AbuseReportsFilteredSearchBar', () => {
    createComponent();

    expect(findFilteredSearchBar().exists()).toBe(true);
  });

  it('renders one AbuseReportRow for each abuse report', () => {
    createComponent();

    expect(findEmptyState().exists()).toBe(false);
    expect(findAbuseReportRows().length).toBe(mockAbuseReports.length);
  });

  it('renders empty state when there are no reports', () => {
    createComponent({
      abuseReports: [],
      pagination: { currentPage: 1, perPage: 20, totalItems: 0 },
    });

    expect(findEmptyState().exists()).toBe(true);
  });

  describe('pagination', () => {
    const pagination = {
      currentPage: 1,
      perPage: 1,
      totalItems: mockAbuseReports.length,
    };

    it('renders GlPagination with the correct props when needed', () => {
      createComponent({ pagination });

      expect(findPagination().exists()).toBe(true);
      expect(findPagination().props()).toMatchObject({
        value: pagination.currentPage,
        perPage: pagination.perPage,
        totalItems: pagination.totalItems,
        prevText: 'Previous',
        nextText: 'Next',
        labelNextPage: 'Go to next page',
        labelPrevPage: 'Go to previous page',
        align: 'center',
      });
    });

    it('does not render GlPagination when not needed', () => {
      createComponent({ pagination: { currentPage: 1, perPage: 2, totalItems: 2 } });

      expect(findPagination().exists()).toBe(false);
    });

    describe('linkGen prop', () => {
      const existingQuery = {
        user: 'mr_okay',
        status: 'closed',
      };
      const expectedGeneratedQuery = {
        ...existingQuery,
        page: '2',
      };

      beforeEach(() => {
        setWindowLocation(`https://localhost?${objectToQuery(existingQuery)}`);
      });

      it('generates the correct page URL', () => {
        createComponent({ pagination });

        const linkGen = findPagination().props('linkGen');
        const generatedUrl = linkGen(expectedGeneratedQuery.page);
        const [, generatedQuery] = generatedUrl.split('?');

        expect(queryToObject(generatedQuery)).toMatchObject(expectedGeneratedQuery);
      });
    });
  });
});

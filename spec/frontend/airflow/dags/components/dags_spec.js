import { GlAlert, GlPagination, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import AirflowDags from '~/airflow/dags/components/dags.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { mockDags } from './mock_data';

describe('AirflowDags', () => {
  let wrapper;

  const createWrapper = (
    dags = [],
    pagination = { page: 1, isLastPage: false, per_page: 2, totalItems: 0 },
  ) => {
    wrapper = mountExtended(AirflowDags, {
      propsData: {
        dags,
        pagination,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findEmptyState = () => wrapper.findByText('There are no DAGs to show');
  const findPagination = () => wrapper.findComponent(GlPagination);

  describe('default (no dags)', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows incubation warning', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('shows empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      expect(findPagination().exists()).toBe(false);
    });
  });

  describe('with dags', () => {
    const createWrapperWithDags = (pagination = {}) => {
      createWrapper(mockDags, {
        page: 1,
        isLastPage: false,
        per_page: 2,
        totalItems: 5,
        ...pagination,
      });
    };

    const findDagsData = () => {
      return wrapper
        .findComponent(GlTableLite)
        .findAll('tbody tr')
        .wrappers.map((tr) => {
          return tr.findAll('td').wrappers.map((td) => {
            const timeAgo = td.findComponent(TimeAgo);

            if (timeAgo.exists()) {
              return {
                type: 'time',
                value: timeAgo.props('time'),
              };
            }

            return {
              type: 'text',
              value: td.text(),
            };
          });
        });
    };

    it('renders the table of Dags with data', () => {
      createWrapperWithDags();

      expect(findDagsData()).toEqual(
        mockDags.map((x) => [
          { type: 'text', value: x.dag_name },
          { type: 'text', value: x.schedule },
          { type: 'time', value: x.next_run },
          { type: 'text', value: String(x.is_active) },
          { type: 'text', value: String(x.is_paused) },
          { type: 'text', value: x.fileloc },
        ]),
      );
    });

    describe('Pagination behaviour', () => {
      it.each`
        pagination                       | expected
        ${{}}                            | ${{ value: 1, prevPage: null, nextPage: 2 }}
        ${{ page: 2 }}                   | ${{ value: 2, prevPage: 1, nextPage: 3 }}
        ${{ isLastPage: true, page: 2 }} | ${{ value: 2, prevPage: 1, nextPage: null }}
      `('with $pagination, sets pagination props', ({ pagination, expected }) => {
        createWrapperWithDags({ ...pagination });

        expect(findPagination().props()).toMatchObject(expected);
      });

      it('generates link for each page', () => {
        createWrapperWithDags();

        const generateLink = findPagination().props('linkGen');

        expect(generateLink(3)).toBe(`${TEST_HOST}/?page=3`);
      });
    });
  });
});

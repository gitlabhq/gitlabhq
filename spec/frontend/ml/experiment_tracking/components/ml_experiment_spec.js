import { GlAlert, GlPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MlExperiment from '~/ml/experiment_tracking/components/ml_experiment.vue';

describe('MlExperiment', () => {
  let wrapper;

  const createWrapper = (
    candidates = [],
    metricNames = [],
    paramNames = [],
    pagination = { page: 1, isLastPage: false, per_page: 2, totalItems: 0 },
  ) => {
    return mountExtended(MlExperiment, {
      provide: { candidates, metricNames, paramNames, pagination },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findEmptyState = () => wrapper.findByText('This experiment has no logged candidates');

  it('shows incubation warning', () => {
    wrapper = createWrapper();

    expect(findAlert().exists()).toBe(true);
  });

  describe('no candidates', () => {
    it('shows empty state', () => {
      wrapper = createWrapper();

      expect(findEmptyState().exists()).toBe(true);
    });

    it('does not show pagination', () => {
      wrapper = createWrapper();

      expect(wrapper.findComponent(GlPagination).exists()).toBe(false);
    });
  });

  describe('with candidates', () => {
    const defaultPagination = { page: 1, isLastPage: false, per_page: 2, totalItems: 5 };

    const createWrapperWithCandidates = (pagination = defaultPagination) => {
      return createWrapper(
        [
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
        ],
        ['rmse', 'auc', 'mae'],
        ['l1_ratio'],
        pagination,
      );
    };

    it('renders correctly', () => {
      wrapper = createWrapperWithCandidates();

      expect(wrapper.element).toMatchSnapshot();
    });

    describe('Pagination behaviour', () => {
      it('should show', () => {
        wrapper = createWrapperWithCandidates();

        expect(wrapper.findComponent(GlPagination).exists()).toBe(true);
      });

      it('should get the page number from the URL', () => {
        wrapper = createWrapperWithCandidates({ ...defaultPagination, page: 2 });

        expect(wrapper.findComponent(GlPagination).props().value).toBe(2);
      });

      it('should not have a prevPage if the page is 1', () => {
        wrapper = createWrapperWithCandidates();

        expect(wrapper.findComponent(GlPagination).props().prevPage).toBe(null);
      });

      it('should set the prevPage to 1 if the page is 2', () => {
        wrapper = createWrapperWithCandidates({ ...defaultPagination, page: 2 });

        expect(wrapper.findComponent(GlPagination).props().prevPage).toBe(1);
      });

      it('should not have a nextPage if isLastPage is true', async () => {
        wrapper = createWrapperWithCandidates({ ...defaultPagination, isLastPage: true });

        expect(wrapper.findComponent(GlPagination).props().nextPage).toBe(null);
      });

      it('should set the nextPage to 2 if the page is 1', () => {
        wrapper = createWrapperWithCandidates();

        expect(wrapper.findComponent(GlPagination).props().nextPage).toBe(2);
      });
    });
  });
});

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import CronJobsPage from '~/kubernetes_dashboard/pages/cron_jobs_page.vue';
import WorkloadLayout from '~/kubernetes_dashboard/components/workload_layout.vue';
import { useFakeDate } from 'helpers/fake_date';
import { k8sCronJobsMock, mockCronJobsStats, mockCronJobsTableItems } from '../graphql/mock_data';

Vue.use(VueApollo);

describe('Kubernetes dashboard cronJobs page', () => {
  let wrapper;

  const configuration = {
    basePath: 'kas/tunnel/url',
    baseOptions: {
      headers: { 'GitLab-Agent-Id': '1' },
    },
  };

  const findWorkloadLayout = () => wrapper.findComponent(WorkloadLayout);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sCronJobs: jest.fn().mockReturnValue(k8sCronJobsMock),
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = (apolloProvider = createApolloProvider()) => {
    wrapper = shallowMount(CronJobsPage, {
      provide: { configuration },
      apolloProvider,
    });
  };

  describe('mounted', () => {
    it('renders WorkloadLayout component', () => {
      createWrapper();

      expect(findWorkloadLayout().exists()).toBe(true);
    });

    it('sets loading prop for the WorkloadLayout', () => {
      createWrapper();

      expect(findWorkloadLayout().props('loading')).toBe(true);
    });

    it('removes loading prop from the WorkloadLayout when the list of cronJobs loaded', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadLayout().props('loading')).toBe(false);
    });
  });

  describe('when gets cronJobs data', () => {
    useFakeDate(2023, 10, 23, 10, 10);

    it('sets correct stats object for the WorkloadLayout', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadLayout().props('stats')).toEqual(mockCronJobsStats);
    });

    it('sets correct table items object for the WorkloadLayout', async () => {
      createWrapper();
      await waitForPromises();

      expect(findWorkloadLayout().props('items')).toMatchObject(mockCronJobsTableItems);
    });
  });

  describe('when gets an error from the cluster_client API', () => {
    const error = new Error('Error from the cluster_client API');
    const createErroredApolloProvider = () => {
      const mockResolvers = {
        Query: {
          k8sCronJobs: jest.fn().mockRejectedValueOnce(error),
        },
      };

      return createMockApollo([], mockResolvers);
    };

    beforeEach(async () => {
      createWrapper(createErroredApolloProvider());
      await waitForPromises();
    });

    it('sets errorMessage prop for the WorkloadLayout', () => {
      expect(findWorkloadLayout().props('errorMessage')).toBe(error.message);
    });
  });
});

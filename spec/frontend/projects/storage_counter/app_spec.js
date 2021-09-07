import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import StorageCounterApp from '~/projects/storage_counter/components/app.vue';
import getProjectStorageCount from '~/projects/storage_counter/queries/project_storage.query.graphql';
import UsageGraph from '~/vue_shared/components/storage_counter/usage_graph.vue';
import { projectStorageCountResponse } from './mock_data';

const localVue = createLocalVue();

describe('Storage counter app', () => {
  let wrapper;

  const createMockApolloProvider = ({ mutationMock }) => {
    localVue.use(VueApollo);

    const requestHandlers = [[getProjectStorageCount, mutationMock]];

    return createMockApollo(requestHandlers);
  };

  const createComponent = ({ provide = {}, mockApollo } = {}) => {
    const defaultProvideValues = {
      projectPath: 'test-project',
    };

    wrapper = shallowMount(StorageCounterApp, {
      localVue,
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvideValues,
        ...provide,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findUsageGraph = () => wrapper.findComponent(UsageGraph);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders app successfully', () => {
    expect(wrapper.text()).toBe('Usage');
  });

  describe('handling apollo fetching error', () => {
    const mutationMock = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    beforeEach(() => {
      const mockApollo = createMockApolloProvider({ mutationMock });
      createComponent({ mockApollo });
    });

    it('renders gl-alert if there is an error', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('rendering <usage-graph />', () => {
    const mutationMock = jest.fn().mockResolvedValue(projectStorageCountResponse);

    beforeEach(() => {
      const mockApollo = createMockApolloProvider({ mutationMock });
      createComponent({ mockApollo });
    });

    it('renders usage-graph component if project.statistics exists', () => {
      expect(findUsageGraph().exists()).toBe(true);
    });

    it('passes project.statistics to usage-graph component', () => {
      const { __typename, ...statistics } = projectStorageCountResponse.data.project.statistics;
      expect(findUsageGraph().props('rootStorageStatistics')).toMatchObject(statistics);
    });
  });
});

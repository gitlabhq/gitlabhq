import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import StorageCounterApp from '~/projects/storage_counter/components/app.vue';
import getProjectStorageCount from '~/projects/storage_counter/queries/project_storage.query.graphql';

const localVue = createLocalVue();

describe('Storage counter app', () => {
  let wrapper;

  const createMockApolloProvider = () => {
    localVue.use(VueApollo);

    const requestHandlers = [
      [getProjectStorageCount, jest.fn().mockRejectedValue(new Error('GraphQL error'))],
    ];

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
    let mockApollo;

    beforeEach(() => {
      mockApollo = createMockApolloProvider();
      createComponent({ mockApollo });
    });

    it('renders gl-alert if there is an error', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });
});

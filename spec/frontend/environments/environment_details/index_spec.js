import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import resolvedEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.json';
import emptyEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.empty.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsDetailPage from '~/environments/environment_details/index.vue';
import ConfirmRollbackModal from '~/environments/components/confirm_rollback_modal.vue';
import EmptyState from '~/environments/environment_details/empty_state.vue';
import getEnvironmentDetails from '~/environments/graphql/queries/environment_details.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

const GRAPHQL_ETAG_KEY = '/graphql/environments';

describe('~/environments/environment_details/index.vue', () => {
  Vue.use(VueApollo);

  let wrapper;
  let routerMock;

  const emptyEnvironmentToRollbackData = { id: '', name: '', lastDeployment: null, retryUrl: '' };
  const environmentToRollbackMock = jest.fn();

  const mockResolvers = {
    Query: {
      environmentToRollback: environmentToRollbackMock,
    },
  };

  const defaultWrapperParameters = {
    resolvedData: resolvedEnvironmentDetails,
    environmentToRollbackData: emptyEnvironmentToRollbackData,
  };

  const createWrapper = ({
    resolvedData,
    environmentToRollbackData,
  } = defaultWrapperParameters) => {
    const mockApollo = createMockApollo(
      [[getEnvironmentDetails, jest.fn().mockResolvedValue(resolvedData)]],
      mockResolvers,
    );
    environmentToRollbackMock.mockReturnValue(
      environmentToRollbackData || emptyEnvironmentToRollbackData,
    );
    const projectFullPath = 'gitlab-group/test-project';
    routerMock = {
      push: jest.fn(),
    };

    return mountExtended(EnvironmentsDetailPage, {
      apolloProvider: mockApollo,
      provide: {
        projectPath: projectFullPath,
        graphqlEtagKey: GRAPHQL_ETAG_KEY,
      },
      propsData: {
        projectFullPath,
        environmentName: 'test-environment-name',
      },
      mocks: {
        $router: routerMock,
      },
    });
  };

  describe('when fetching data', () => {
    it('should show a loading indicator', () => {
      wrapper = createWrapper();

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.findComponent(GlTableLite).exists()).not.toBe(true);
    });
  });

  describe('when data is fetched', () => {
    describe('and there are deployments', () => {
      beforeEach(async () => {
        wrapper = createWrapper();
        await waitForPromises();
      });
      it('should render a table when query is loaded', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).not.toBe(true);
        expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
      });

      describe('on rollback', () => {
        it('sets the page back to default', () => {
          wrapper.findComponent(ConfirmRollbackModal).vm.$emit('rollback');

          expect(routerMock.push).toHaveBeenCalledWith({ query: {} });
        });
      });
    });

    describe('and there are no deployments', () => {
      beforeEach(async () => {
        wrapper = createWrapper({ resolvedData: emptyEnvironmentDetails });
        await waitForPromises();
      });

      it('should render empty state component', () => {
        expect(wrapper.findComponent(GlTableLite).exists()).toBe(false);
        expect(wrapper.findComponent(EmptyState).exists()).toBe(true);
      });
    });
  });
});

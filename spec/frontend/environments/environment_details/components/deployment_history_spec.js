import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlTableLite, GlSorting } from '@gitlab/ui';
import resolvedEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.json';
import emptyEnvironmentDetails from 'test_fixtures/graphql/environments/graphql/queries/environment_details.query.graphql.empty.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeploymentHistory from '~/environments/environment_details/components/deployment_history.vue';
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
  let environmentDetailsMock;

  const projectFullPath = 'gitlab-group/test-project';
  const environmentName = 'test-environment-name';

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
    environmentDetailsMock = jest.fn().mockResolvedValue(resolvedData);

    const mockApollo = createMockApollo(
      [[getEnvironmentDetails, environmentDetailsMock]],
      mockResolvers,
    );
    environmentToRollbackMock.mockReturnValue(
      environmentToRollbackData || emptyEnvironmentToRollbackData,
    );
    routerMock = {
      push: jest.fn(),
    };

    return mountExtended(DeploymentHistory, {
      apolloProvider: mockApollo,
      provide: {
        projectPath: projectFullPath,
        graphqlEtagKey: GRAPHQL_ETAG_KEY,
      },
      propsData: {
        projectFullPath,
        environmentName,
      },
      mocks: {
        $router: routerMock,
      },
    });
  };

  const findSorting = () => wrapper.findComponent(GlSorting);

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

      it('should render a table', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.findComponent(GlTableLite).exists()).toBe(true);
      });

      describe('on rollback', () => {
        it('sets the page back to default', () => {
          wrapper.findComponent(ConfirmRollbackModal).vm.$emit('rollback');
          expect(routerMock.push).toHaveBeenCalledWith({ query: {} });
        });
      });

      describe('sorting', () => {
        const defaultSortingProps = {
          isAscending: false,
          sortBy: 'createdAt',
        };

        const defaultQueryVariables = {
          projectFullPath,
          environmentName,
          statuses: [],
          orderBy: {
            createdAt: 'DESC',
          },
        };

        it('should render sorting component with default props', () => {
          expect(findSorting().props()).toMatchObject(defaultSortingProps);
        });

        describe('sorting direction changes', () => {
          it('updates props when direction changes', async () => {
            findSorting().vm.$emit('sortDirectionChange');
            await nextTick();

            expect(findSorting().props()).toMatchObject({
              ...defaultSortingProps,
              isAscending: true,
            });
          });

          it('requests data with updated direction', async () => {
            expect(environmentDetailsMock).toHaveBeenCalledWith(
              expect.objectContaining(defaultQueryVariables),
            );

            findSorting().vm.$emit('sortDirectionChange');
            await nextTick();

            expect(environmentDetailsMock).toHaveBeenCalledWith(
              expect.objectContaining({
                ...defaultQueryVariables,
                orderBy: {
                  createdAt: 'ASC',
                },
              }),
            );
          });
        });

        describe('sortBy field changes', () => {
          const newSortField = 'finishedAt';

          it('updates props when sortBy field changes', async () => {
            findSorting().vm.$emit('sortByChange', newSortField);
            await nextTick();

            expect(findSorting().props()).toMatchObject({
              ...defaultSortingProps,
              sortBy: newSortField,
            });
          });

          it('requests data with updated sort field', async () => {
            expect(environmentDetailsMock).toHaveBeenCalledWith(
              expect.objectContaining(defaultQueryVariables),
            );

            findSorting().vm.$emit('sortByChange', newSortField);
            await nextTick();

            expect(environmentDetailsMock).toHaveBeenCalledWith(
              expect.objectContaining({
                ...defaultQueryVariables,
                statuses: ['SUCCESS', 'FAILED', 'CANCELED'],
                orderBy: {
                  [newSortField]: 'DESC',
                },
              }),
            );
          });
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

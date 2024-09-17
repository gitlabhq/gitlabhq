import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import PagesDeployments from '~/gitlab_pages/components/deployments.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import getProjectPagesDeploymentsQuery from '~/gitlab_pages/queries/get_project_pages_deployments.graphql';
import waitForPromises from 'helpers/wait_for_promises';

describe('PagesDeployments', () => {
  Vue.use(VueApollo);
  let wrapper;

  const getProjectPagesDeploymentsQueryHandler = jest
    .fn()
    .mockImplementation(({ versioned, after }) => {
      return {
        data: {
          project: {
            id: 'gid://gitlab/Project/1',
            pagesDeployments: {
              __typename: 'PagesDeploymentConnection',
              count: 14,
              pageInfo: {
                __typename: 'PageInfo',
                startCursor:
                  'eyJjcmVhdGVkX2F0IjoiMjAyNC0wNS0yMiAxMzozNzoyMi40MTk4MzcwMDAgKzAwMDAiLCJpZCI6IjQwIn0',
                endCursor:
                  'eyJjcmVhdGVkX2F0IjoiMjAyNC0wNS0yMiAxMzozNzoyMi40MTk4MzcwMDAgKzAwMDAiLCJpZCI6IjQwIn0',
                hasNextPage: !after, // This mimics this result being a second page
                hasPreviousPage: Boolean(after),
              },
              nodes: Array(after ? 4 : 10)
                .fill(null)
                .map((_, i) => ({
                  __typename: 'PagesDeployment',
                  id: `gid://gitlab/PagesDeployment/${!after ? i + 1 : i + 11}`,
                  active: true,
                  rootDirectory: 'public',
                  ciBuildId: '499',
                  createdAt: '2024-05-22T13:37:22Z',
                  deletedAt: null,
                  fileCount: 3,
                  pathPrefix: versioned ? '_stg' : '',
                  size: 1082,
                  updatedAt: '2024-05-23T11:48:34Z',
                  expiresAt: versioned ? '2024-05-23T13:37:22Z' : null,
                  url: 'http://abc.pages.io/',
                })),
            },
          },
        },
      };
    });

  const findAllPrimaryDeployments = () => wrapper.findAllByTestId('primary-deployment');
  const findAllParallelDeployments = () => wrapper.findAllByTestId('parallel-deployment');
  const findPrimaryDeploymentsLoadMoreComponent = () =>
    wrapper.findByTestId('load-more-primary-deployments');
  const findParallelDeploymentsLoadMoreComponent = () =>
    wrapper.findByTestId('load-more-parallel-deployments');

  const createComponent = () => {
    wrapper = shallowMountExtended(PagesDeployments, {
      apolloProvider: createMockApollo([
        [getProjectPagesDeploymentsQuery, getProjectPagesDeploymentsQueryHandler],
      ]),
      provide: {
        projectFullPath: 'my-group/my-project',
      },
    });
  };

  describe('default behaviour', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('renders the component', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('calls the query 2 times', () => {
      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledTimes(2);
    });

    it('calls the primary deployments query', () => {
      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          active: true,
          fullPath: 'my-group/my-project',
          versioned: false,
        }),
      );
    });

    it('calls the parallels deployments query', () => {
      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          active: true,
          fullPath: 'my-group/my-project',
          versioned: true,
        }),
      );
    });

    it('renders a list for all primary deployments', () => {
      expect(findAllPrimaryDeployments().length).toBe(10);
    });

    it('renders a list for all parallel deployments', () => {
      expect(findAllParallelDeployments().length).toBe(10);
    });
  });

  describe('when the user loads more deployments', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('does include the "load more" component for primary deployments', () => {
      expect(findPrimaryDeploymentsLoadMoreComponent().exists()).toBe(true);
    });

    it('does include the "load more" component for parallel deployments', () => {
      expect(findParallelDeploymentsLoadMoreComponent().exists()).toBe(true);
    });

    it('fetches more primary deployments', async () => {
      findPrimaryDeploymentsLoadMoreComponent().vm.$emit('load-more');
      await nextTick();

      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          versioned: false,
          after: expect.any(String),
        }),
      );

      await waitForPromises();

      expect(findPrimaryDeploymentsLoadMoreComponent().exists()).toBe(false);
    });

    it('fetches more parallel deployments', async () => {
      findParallelDeploymentsLoadMoreComponent().vm.$emit('load-more');
      await nextTick();

      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          versioned: true,
          after: expect.any(String),
        }),
      );

      await waitForPromises();

      expect(findParallelDeploymentsLoadMoreComponent().exists()).toBe(false);
    });
  });

  describe('when the "Include stopped deployments" toggle is switched on', () => {
    beforeEach(async () => {
      createComponent();
      wrapper.findByTestId('show-inactive-toggle').vm.$emit('change', true);
      await waitForPromises();
    });

    it('fetches the primaryDeployments with the "active" filter set to undefined', () => {
      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          versioned: false,
          active: undefined,
        }),
      );
    });

    it('fetches the parallelDeployments with the "active" filter set to undefined', () => {
      expect(getProjectPagesDeploymentsQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          versioned: true,
          active: undefined,
        }),
      );
    });
  });

  describe.each`
    type          | testid
    ${'primary'}  | ${'primary-deployment'}
    ${'parallel'} | ${'parallel-deployment'}
  `('if a $type PagesDeployment child emits an error', ({ testid }) => {
    const errorMessage = 'Foo';

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
      wrapper
        .findByTestId(testid)
        .vm.$emit('error', { id: 'gid://gitlab/PagesDeployment/1', message: errorMessage });
      await nextTick();
    });

    it('shows an alert with this message', () => {
      expect(wrapper.findByTestId('alert').text()).toBe(errorMessage);
    });
  });

  describe('if there are no deployments yet', () => {
    beforeEach(async () => {
      getProjectPagesDeploymentsQueryHandler.mockImplementation(() => ({
        data: {
          project: {
            id: 'gid://gitlab/Project/1',
            pagesDeployments: {
              count: 0,
              pageInfo: {
                startCursor: null,
                endCursor: null,
                hasNextPage: false,
                hasPreviousPage: false,
              },
              edges: [],
            },
          },
        },
      }));
      createComponent();
      await waitForPromises();
    });

    it('displays an empty state text', () => {
      expect(wrapper.text()).toContain('No deployments yet');
    });
  });

  describe('loading state', () => {
    beforeEach(() => {
      getProjectPagesDeploymentsQueryHandler.mockImplementation(() => Promise);
      createComponent();
    });

    it('displays the loading icon', () => {
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});

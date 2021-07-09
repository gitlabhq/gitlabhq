import { cloneDeep } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import allReleasesQuery from 'shared_queries/releases/all_releases.query.graphql';
import createFlash from '~/flash';
import { historyPushState } from '~/lib/utils/common_utils';
import ReleasesIndexApolloClientApp from '~/releases/components/app_index_apollo_client.vue';
import ReleaseBlock from '~/releases/components/release_block.vue';
import ReleaseSkeletonLoader from '~/releases/components/release_skeleton_loader.vue';
import ReleasesEmptyState from '~/releases/components/releases_empty_state.vue';
import ReleasesPaginationApolloClient from '~/releases/components/releases_pagination_apollo_client.vue';
import ReleasesSortApolloClient from '~/releases/components/releases_sort_apollo_client.vue';
import { PAGE_SIZE, CREATED_ASC, DEFAULT_SORT } from '~/releases/constants';

Vue.use(VueApollo);

jest.mock('~/flash');

let mockQueryParams;
jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  historyPushState: jest.fn(),
}));

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterByName: jest
    .fn()
    .mockImplementation((parameterName) => mockQueryParams[parameterName]),
}));

describe('app_index_apollo_client.vue', () => {
  const originalAllReleasesQueryResponse = getJSONFixture(
    'graphql/releases/graphql/queries/all_releases.query.graphql.json',
  );
  const projectPath = 'project/path';
  const newReleasePath = 'path/to/new/release/page';
  const before = 'beforeCursor';
  const after = 'afterCursor';

  let wrapper;
  let allReleases;
  let singleRelease;
  let noReleases;
  let queryMock;

  const createComponent = ({
    singleResponse = Promise.resolve(singleRelease),
    fullResponse = Promise.resolve(allReleases),
  } = {}) => {
    const apolloProvider = createMockApollo([
      [
        allReleasesQuery,
        queryMock.mockImplementation((vars) => {
          return vars.first === 1 ? singleResponse : fullResponse;
        }),
      ],
    ]);

    wrapper = shallowMountExtended(ReleasesIndexApolloClientApp, {
      apolloProvider,
      provide: {
        newReleasePath,
        projectPath,
      },
    });
  };

  beforeEach(() => {
    mockQueryParams = {};

    allReleases = cloneDeep(originalAllReleasesQueryResponse);

    singleRelease = cloneDeep(originalAllReleasesQueryResponse);
    singleRelease.data.project.releases.nodes.splice(
      1,
      singleRelease.data.project.releases.nodes.length,
    );

    noReleases = cloneDeep(originalAllReleasesQueryResponse);
    noReleases.data.project.releases.nodes = [];

    queryMock = jest.fn();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  // Finders
  const findLoadingIndicator = () => wrapper.findComponent(ReleaseSkeletonLoader);
  const findEmptyState = () => wrapper.findComponent(ReleasesEmptyState);
  const findNewReleaseButton = () =>
    wrapper.findByText(ReleasesIndexApolloClientApp.i18n.newRelease);
  const findAllReleaseBlocks = () => wrapper.findAllComponents(ReleaseBlock);
  const findPagination = () => wrapper.findComponent(ReleasesPaginationApolloClient);
  const findSort = () => wrapper.findComponent(ReleasesSortApolloClient);

  // Tests
  describe('component states', () => {
    // These need to be defined as functions, since `singleRelease` and
    // `allReleases` are generated in a `beforeEach`, and therefore
    // aren't available at test definition time.
    const getInProgressResponse = () => new Promise(() => {});
    const getErrorResponse = () => Promise.reject(new Error('Oops!'));
    const getSingleRequestLoadedResponse = () => Promise.resolve(singleRelease);
    const getFullRequestLoadedResponse = () => Promise.resolve(allReleases);
    const getLoadedEmptyResponse = () => Promise.resolve(noReleases);

    const toDescription = (bool) => (bool ? 'does' : 'does not');

    describe.each`
      description                                                       | singleResponseFn                  | fullResponseFn                  | loadingIndicator | emptyState | flashMessage | releaseCount | pagination
      ${'both requests loading'}                                        | ${getInProgressResponse}          | ${getInProgressResponse}        | ${true}          | ${false}   | ${false}     | ${0}         | ${false}
      ${'both requests failed'}                                         | ${getErrorResponse}               | ${getErrorResponse}             | ${false}         | ${false}   | ${true}      | ${0}         | ${false}
      ${'both requests loaded'}                                         | ${getSingleRequestLoadedResponse} | ${getFullRequestLoadedResponse} | ${false}         | ${false}   | ${false}     | ${2}         | ${true}
      ${'both requests loaded with no results'}                         | ${getLoadedEmptyResponse}         | ${getLoadedEmptyResponse}       | ${false}         | ${true}    | ${false}     | ${0}         | ${false}
      ${'single request loading, full request loaded'}                  | ${getInProgressResponse}          | ${getFullRequestLoadedResponse} | ${false}         | ${false}   | ${false}     | ${2}         | ${true}
      ${'single request loading, full request failed'}                  | ${getInProgressResponse}          | ${getErrorResponse}             | ${true}          | ${false}   | ${true}      | ${0}         | ${false}
      ${'single request loaded, full request loading'}                  | ${getSingleRequestLoadedResponse} | ${getInProgressResponse}        | ${true}          | ${false}   | ${false}     | ${1}         | ${false}
      ${'single request loaded, full request failed'}                   | ${getSingleRequestLoadedResponse} | ${getErrorResponse}             | ${false}         | ${false}   | ${true}      | ${1}         | ${false}
      ${'single request failed, full request loading'}                  | ${getErrorResponse}               | ${getInProgressResponse}        | ${true}          | ${false}   | ${false}     | ${0}         | ${false}
      ${'single request failed, full request loaded'}                   | ${getErrorResponse}               | ${getFullRequestLoadedResponse} | ${false}         | ${false}   | ${false}     | ${2}         | ${true}
      ${'single request loaded with no results, full request loading'}  | ${getLoadedEmptyResponse}         | ${getInProgressResponse}        | ${true}          | ${false}   | ${false}     | ${0}         | ${false}
      ${'single request loading, full request loadied with no results'} | ${getInProgressResponse}          | ${getLoadedEmptyResponse}       | ${false}         | ${true}    | ${false}     | ${0}         | ${false}
    `(
      '$description',
      ({
        singleResponseFn,
        fullResponseFn,
        loadingIndicator,
        emptyState,
        flashMessage,
        releaseCount,
        pagination,
      }) => {
        beforeEach(() => {
          createComponent({
            singleResponse: singleResponseFn(),
            fullResponse: fullResponseFn(),
          });
        });

        it(`${toDescription(loadingIndicator)} render a loading indicator`, () => {
          expect(findLoadingIndicator().exists()).toBe(loadingIndicator);
        });

        it(`${toDescription(emptyState)} render an empty state`, () => {
          expect(findEmptyState().exists()).toBe(emptyState);
        });

        it(`${toDescription(flashMessage)} show a flash message`, () => {
          if (flashMessage) {
            expect(createFlash).toHaveBeenCalledWith({
              message: ReleasesIndexApolloClientApp.i18n.errorMessage,
              captureError: true,
              error: expect.any(Error),
            });
          } else {
            expect(createFlash).not.toHaveBeenCalled();
          }
        });

        it(`renders ${releaseCount} release(s)`, () => {
          expect(findAllReleaseBlocks()).toHaveLength(releaseCount);
        });

        it(`${toDescription(pagination)} render the pagination controls`, () => {
          expect(findPagination().exists()).toBe(pagination);
        });

        it('does render the "New release" button', () => {
          expect(findNewReleaseButton().exists()).toBe(true);
        });

        it('does render the sort controls', () => {
          expect(findSort().exists()).toBe(true);
        });
      },
    );
  });

  describe('URL parameters', () => {
    describe('when the URL contains no query parameters', () => {
      beforeEach(() => {
        createComponent();
      });

      it('makes a request with the correct GraphQL query parameters', () => {
        expect(queryMock).toHaveBeenCalledTimes(2);

        expect(queryMock).toHaveBeenCalledWith({
          first: 1,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });

        expect(queryMock).toHaveBeenCalledWith({
          first: PAGE_SIZE,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });
      });
    });

    describe('when the URL contains a "before" query parameter', () => {
      beforeEach(() => {
        mockQueryParams = { before };
        createComponent();
      });

      it('makes a request with the correct GraphQL query parameters', () => {
        expect(queryMock).toHaveBeenCalledTimes(1);

        expect(queryMock).toHaveBeenCalledWith({
          before,
          last: PAGE_SIZE,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });
      });
    });

    describe('when the URL contains an "after" query parameter', () => {
      beforeEach(() => {
        mockQueryParams = { after };
        createComponent();
      });

      it('makes a request with the correct GraphQL query parameters', () => {
        expect(queryMock).toHaveBeenCalledTimes(2);

        expect(queryMock).toHaveBeenCalledWith({
          after,
          first: 1,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });

        expect(queryMock).toHaveBeenCalledWith({
          after,
          first: PAGE_SIZE,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });
      });
    });

    describe('when the URL contains both "before" and "after" query parameters', () => {
      beforeEach(() => {
        mockQueryParams = { before, after };
        createComponent();
      });

      it('ignores the "before" parameter and behaves as if only the "after" parameter was provided', () => {
        expect(queryMock).toHaveBeenCalledTimes(2);

        expect(queryMock).toHaveBeenCalledWith({
          after,
          first: 1,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });

        expect(queryMock).toHaveBeenCalledWith({
          after,
          first: PAGE_SIZE,
          fullPath: projectPath,
          sort: DEFAULT_SORT,
        });
      });
    });
  });

  describe('New release button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the new release button with the correct href', () => {
      expect(findNewReleaseButton().attributes().href).toBe(newReleasePath);
    });
  });

  describe('pagination', () => {
    beforeEach(() => {
      mockQueryParams = { before };
      createComponent();
    });

    it('requeries the GraphQL endpoint when a pagination button is clicked', async () => {
      expect(queryMock.mock.calls).toEqual([[expect.objectContaining({ before })]]);

      mockQueryParams = { after };
      findPagination().vm.$emit('next', after);

      await wrapper.vm.$nextTick();

      expect(queryMock.mock.calls).toEqual([
        [expect.objectContaining({ before })],
        [expect.objectContaining({ after })],
        [expect.objectContaining({ after })],
      ]);
    });
  });

  describe('sorting', () => {
    beforeEach(() => {
      createComponent();
    });

    it(`sorts by ${DEFAULT_SORT} by default`, () => {
      expect(queryMock.mock.calls).toEqual([
        [expect.objectContaining({ sort: DEFAULT_SORT })],
        [expect.objectContaining({ sort: DEFAULT_SORT })],
      ]);
    });

    it('requeries the GraphQL endpoint and updates the URL when the sort is changed', async () => {
      findSort().vm.$emit('input', CREATED_ASC);

      await wrapper.vm.$nextTick();

      expect(queryMock.mock.calls).toEqual([
        [expect.objectContaining({ sort: DEFAULT_SORT })],
        [expect.objectContaining({ sort: DEFAULT_SORT })],
        [expect.objectContaining({ sort: CREATED_ASC })],
        [expect.objectContaining({ sort: CREATED_ASC })],
      ]);

      // URL manipulation is tested in more detail in the `describe` block below
      expect(historyPushState).toHaveBeenCalled();
    });

    it('does not requery the GraphQL endpoint or update the URL if the sort is updated to the same value', async () => {
      findSort().vm.$emit('input', DEFAULT_SORT);

      await wrapper.vm.$nextTick();

      expect(queryMock.mock.calls).toEqual([
        [expect.objectContaining({ sort: DEFAULT_SORT })],
        [expect.objectContaining({ sort: DEFAULT_SORT })],
      ]);

      expect(historyPushState).not.toHaveBeenCalled();
    });
  });

  describe('sorting + pagination interaction', () => {
    const nonPaginationQueryParam = 'nonPaginationQueryParam';

    beforeEach(() => {
      historyPushState.mockImplementation((newUrl) => {
        mockQueryParams = Object.fromEntries(new URL(newUrl).searchParams);
      });
    });

    describe.each`
      queryParamsBefore                      | paramName   | paramInitialValue
      ${{ before, nonPaginationQueryParam }} | ${'before'} | ${before}
      ${{ after, nonPaginationQueryParam }}  | ${'after'}  | ${after}
    `(
      'when the URL contains a "$paramName" pagination cursor',
      ({ queryParamsBefore, paramName, paramInitialValue }) => {
        beforeEach(async () => {
          mockQueryParams = queryParamsBefore;
          createComponent();

          findSort().vm.$emit('input', CREATED_ASC);

          await wrapper.vm.$nextTick();
        });

        it(`resets the page's "${paramName}" pagination cursor when the sort is changed`, () => {
          const firstRequestVariables = queryMock.mock.calls[0][0];
          // Might be request #2 or #3, depending on the pagination direction
          const mostRecentRequestVariables =
            queryMock.mock.calls[queryMock.mock.calls.length - 1][0];

          expect(firstRequestVariables[paramName]).toBe(paramInitialValue);
          expect(mostRecentRequestVariables[paramName]).toBeUndefined();
        });

        it(`updates the URL to not include the "${paramName}" URL query parameter`, () => {
          expect(historyPushState).toHaveBeenCalledTimes(1);

          const updatedUrlQueryParams = Object.fromEntries(
            new URL(historyPushState.mock.calls[0][0]).searchParams,
          );

          expect(updatedUrlQueryParams[paramName]).toBeUndefined();
        });
      },
    );
  });
});

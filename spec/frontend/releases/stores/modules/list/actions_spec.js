import { cloneDeep } from 'lodash';
import testAction from 'helpers/vuex_action_helper';
import { getJSONFixture } from 'helpers/fixtures';
import {
  fetchReleases,
  fetchReleasesGraphQl,
  fetchReleasesRest,
  receiveReleasesError,
} from '~/releases/stores/modules/list/actions';
import createState from '~/releases/stores/modules/list/state';
import * as types from '~/releases/stores/modules/list/mutation_types';
import api from '~/api';
import { gqClient, convertAllReleasesGraphQLResponse } from '~/releases/util';
import {
  normalizeHeaders,
  parseIntPagination,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { pageInfoHeadersWithoutPagination } from '../../../mock_data';
import allReleasesQuery from '~/releases/queries/all_releases.query.graphql';
import { PAGE_SIZE } from '~/releases/constants';

const originalRelease = getJSONFixture('api/releases/release.json');
const originalReleases = [originalRelease];

const originalGraphqlReleasesResponse = getJSONFixture(
  'graphql/releases/queries/all_releases.query.graphql.json',
);

describe('Releases State actions', () => {
  let mockedState;
  let releases;
  let graphqlReleasesResponse;

  const projectPath = 'root/test-project';
  const projectId = 19;
  const before = 'testBeforeCursor';
  const after = 'testAfterCursor';
  const page = 2;

  beforeEach(() => {
    mockedState = {
      ...createState({
        projectId,
        projectPath,
      }),
    };

    releases = convertObjectPropsToCamelCase(originalReleases, { deep: true });
    graphqlReleasesResponse = cloneDeep(originalGraphqlReleasesResponse);
  });

  describe('when all the necessary GraphQL feature flags are enabled', () => {
    beforeEach(() => {
      mockedState.useGraphQLEndpoint = true;
    });

    describe('fetchReleases', () => {
      it('dispatches fetchReleasesGraphQl with before and after parameters', () => {
        return testAction(
          fetchReleases,
          { before, after, page },
          mockedState,
          [],
          [
            {
              type: 'fetchReleasesGraphQl',
              payload: { before, after },
            },
          ],
        );
      });
    });
  });

  describe('when at least one of the GraphQL feature flags is disabled', () => {
    beforeEach(() => {
      mockedState.useGraphQLEndpoint = false;
    });

    describe('fetchReleases', () => {
      it('dispatches fetchReleasesRest with a page parameter', () => {
        return testAction(
          fetchReleases,
          { before, after, page },
          mockedState,
          [],
          [
            {
              type: 'fetchReleasesRest',
              payload: { page },
            },
          ],
        );
      });
    });
  });

  describe('fetchReleasesGraphQl', () => {
    describe('GraphQL query variables', () => {
      let vuexParams;

      beforeEach(() => {
        jest.spyOn(gqClient, 'query');

        vuexParams = { dispatch: jest.fn(), commit: jest.fn(), state: mockedState };
      });

      describe('when neither a before nor an after parameter is provided', () => {
        beforeEach(() => {
          fetchReleasesGraphQl(vuexParams, { before: undefined, after: undefined });
        });

        it('makes a GraphQl query with a first variable', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, first: PAGE_SIZE },
          });
        });
      });

      describe('when only a before parameter is provided', () => {
        beforeEach(() => {
          fetchReleasesGraphQl(vuexParams, { before, after: undefined });
        });

        it('makes a GraphQl query with last and before variables', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, last: PAGE_SIZE, before },
          });
        });
      });

      describe('when only an after parameter is provided', () => {
        beforeEach(() => {
          fetchReleasesGraphQl(vuexParams, { before: undefined, after });
        });

        it('makes a GraphQl query with first and after variables', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, first: PAGE_SIZE, after },
          });
        });
      });

      describe('when both before and after parameters are provided', () => {
        it('throws an error', () => {
          const callFetchReleasesGraphQl = () => {
            fetchReleasesGraphQl(vuexParams, { before, after });
          };

          expect(callFetchReleasesGraphQl).toThrowError(
            'Both a `before` and an `after` parameter were provided to fetchReleasesGraphQl. These parameters cannot be used together.',
          );
        });
      });
    });

    describe('when the request is successful', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockResolvedValue(graphqlReleasesResponse);
      });

      it(`commits ${types.REQUEST_RELEASES} and ${types.RECEIVE_RELEASES_SUCCESS}`, () => {
        const convertedResponse = convertAllReleasesGraphQLResponse(graphqlReleasesResponse);

        return testAction(
          fetchReleasesGraphQl,
          {},
          mockedState,
          [
            {
              type: types.REQUEST_RELEASES,
            },
            {
              type: types.RECEIVE_RELEASES_SUCCESS,
              payload: {
                data: convertedResponse.data,
                graphQlPageInfo: convertedResponse.paginationInfo,
              },
            },
          ],
          [],
        );
      });
    });

    describe('when the request fails', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockRejectedValue(new Error('Something went wrong!'));
      });

      it(`commits ${types.REQUEST_RELEASES} and dispatch receiveReleasesError`, () => {
        return testAction(
          fetchReleasesGraphQl,
          {},
          mockedState,
          [
            {
              type: types.REQUEST_RELEASES,
            },
          ],
          [
            {
              type: 'receiveReleasesError',
            },
          ],
        );
      });
    });
  });

  describe('fetchReleasesRest', () => {
    describe('REST query parameters', () => {
      let vuexParams;

      beforeEach(() => {
        jest
          .spyOn(api, 'releases')
          .mockResolvedValue({ data: releases, headers: pageInfoHeadersWithoutPagination });

        vuexParams = { dispatch: jest.fn(), commit: jest.fn(), state: mockedState };
      });

      describe('when a page parameter is provided', () => {
        beforeEach(() => {
          fetchReleasesRest(vuexParams, { page: 2 });
        });

        it('makes a REST query with a page query parameter', () => {
          expect(api.releases).toHaveBeenCalledWith(projectId, { page });
        });
      });
    });

    describe('when the request is successful', () => {
      beforeEach(() => {
        jest
          .spyOn(api, 'releases')
          .mockResolvedValue({ data: releases, headers: pageInfoHeadersWithoutPagination });
      });

      it(`commits ${types.REQUEST_RELEASES} and ${types.RECEIVE_RELEASES_SUCCESS}`, () => {
        return testAction(
          fetchReleasesRest,
          {},
          mockedState,
          [
            {
              type: types.REQUEST_RELEASES,
            },
            {
              type: types.RECEIVE_RELEASES_SUCCESS,
              payload: {
                data: convertObjectPropsToCamelCase(releases, { deep: true }),
                restPageInfo: parseIntPagination(
                  normalizeHeaders(pageInfoHeadersWithoutPagination),
                ),
              },
            },
          ],
          [],
        );
      });
    });

    describe('when the request fails', () => {
      beforeEach(() => {
        jest.spyOn(api, 'releases').mockRejectedValue(new Error('Something went wrong!'));
      });

      it(`commits ${types.REQUEST_RELEASES} and dispatch receiveReleasesError`, () => {
        return testAction(
          fetchReleasesRest,
          {},
          mockedState,
          [
            {
              type: types.REQUEST_RELEASES,
            },
          ],
          [
            {
              type: 'receiveReleasesError',
            },
          ],
        );
      });
    });
  });

  describe('receiveReleasesError', () => {
    it('should commit RECEIVE_RELEASES_ERROR mutation', () => {
      return testAction(
        receiveReleasesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_ERROR }],
        [],
      );
    });
  });
});

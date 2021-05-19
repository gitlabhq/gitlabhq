import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import testAction from 'helpers/vuex_action_helper';
import { PAGE_SIZE } from '~/releases/constants';
import allReleasesQuery from '~/releases/graphql/queries/all_releases.query.graphql';
import {
  fetchReleases,
  receiveReleasesError,
  setSorting,
} from '~/releases/stores/modules/index/actions';
import * as types from '~/releases/stores/modules/index/mutation_types';
import createState from '~/releases/stores/modules/index/state';
import { gqClient, convertAllReleasesGraphQLResponse } from '~/releases/util';

const originalGraphqlReleasesResponse = getJSONFixture(
  'graphql/releases/graphql/queries/all_releases.query.graphql.json',
);

describe('Releases State actions', () => {
  let mockedState;
  let graphqlReleasesResponse;

  const projectPath = 'root/test-project';
  const projectId = 19;
  const before = 'testBeforeCursor';
  const after = 'testAfterCursor';

  beforeEach(() => {
    mockedState = {
      ...createState({
        projectId,
        projectPath,
      }),
    };

    graphqlReleasesResponse = cloneDeep(originalGraphqlReleasesResponse);
  });

  describe('fetchReleases', () => {
    describe('GraphQL query variables', () => {
      let vuexParams;

      beforeEach(() => {
        jest.spyOn(gqClient, 'query');

        vuexParams = { dispatch: jest.fn(), commit: jest.fn(), state: mockedState };
      });

      describe('when neither a before nor an after parameter is provided', () => {
        beforeEach(() => {
          fetchReleases(vuexParams, { before: undefined, after: undefined });
        });

        it('makes a GraphQl query with a first variable', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, first: PAGE_SIZE, sort: 'RELEASED_AT_DESC' },
          });
        });
      });

      describe('when only a before parameter is provided', () => {
        beforeEach(() => {
          fetchReleases(vuexParams, { before, after: undefined });
        });

        it('makes a GraphQl query with last and before variables', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, last: PAGE_SIZE, before, sort: 'RELEASED_AT_DESC' },
          });
        });
      });

      describe('when only an after parameter is provided', () => {
        beforeEach(() => {
          fetchReleases(vuexParams, { before: undefined, after });
        });

        it('makes a GraphQl query with first and after variables', () => {
          expect(gqClient.query).toHaveBeenCalledWith({
            query: allReleasesQuery,
            variables: { fullPath: projectPath, first: PAGE_SIZE, after, sort: 'RELEASED_AT_DESC' },
          });
        });
      });

      describe('when both before and after parameters are provided', () => {
        it('throws an error', () => {
          const callFetchReleases = () => {
            fetchReleases(vuexParams, { before, after });
          };

          expect(callFetchReleases).toThrowError(
            'Both a `before` and an `after` parameter were provided to fetchReleases. These parameters cannot be used together.',
          );
        });
      });

      describe('when the sort parameters are provided', () => {
        it.each`
          sort      | orderBy          | ReleaseSort
          ${'asc'}  | ${'released_at'} | ${'RELEASED_AT_ASC'}
          ${'desc'} | ${'released_at'} | ${'RELEASED_AT_DESC'}
          ${'asc'}  | ${'created_at'}  | ${'CREATED_ASC'}
          ${'desc'} | ${'created_at'}  | ${'CREATED_DESC'}
        `(
          'correctly sets $ReleaseSort based on $sort and $orderBy',
          ({ sort, orderBy, ReleaseSort }) => {
            mockedState.sorting.sort = sort;
            mockedState.sorting.orderBy = orderBy;

            fetchReleases(vuexParams, { before: undefined, after: undefined });

            expect(gqClient.query).toHaveBeenCalledWith({
              query: allReleasesQuery,
              variables: { fullPath: projectPath, first: PAGE_SIZE, sort: ReleaseSort },
            });
          },
        );
      });
    });

    describe('when the request is successful', () => {
      beforeEach(() => {
        jest.spyOn(gqClient, 'query').mockResolvedValue(graphqlReleasesResponse);
      });

      it(`commits ${types.REQUEST_RELEASES} and ${types.RECEIVE_RELEASES_SUCCESS}`, () => {
        const convertedResponse = convertAllReleasesGraphQLResponse(graphqlReleasesResponse);

        return testAction(
          fetchReleases,
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
                pageInfo: convertedResponse.paginationInfo,
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
          fetchReleases,
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

  describe('setSorting', () => {
    it('should commit SET_SORTING', () => {
      return testAction(
        setSorting,
        { orderBy: 'released_at', sort: 'asc' },
        null,
        [{ type: types.SET_SORTING, payload: { orderBy: 'released_at', sort: 'asc' } }],
        [],
      );
    });
  });
});

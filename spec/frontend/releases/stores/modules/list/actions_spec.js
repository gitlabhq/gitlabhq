import { cloneDeep } from 'lodash';
import testAction from 'helpers/vuex_action_helper';
import {
  requestReleases,
  fetchReleases,
  receiveReleasesSuccess,
  receiveReleasesError,
} from '~/releases/stores/modules/list/actions';
import createState from '~/releases/stores/modules/list/state';
import * as types from '~/releases/stores/modules/list/mutation_types';
import api from '~/api';
import { gqClient, convertGraphQLResponse } from '~/releases/util';
import { parseIntPagination, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import {
  pageInfoHeadersWithoutPagination,
  releases as originalReleases,
  graphqlReleasesResponse as originalGraphqlReleasesResponse,
} from '../../../mock_data';
import allReleasesQuery from '~/releases/queries/all_releases.query.graphql';

describe('Releases State actions', () => {
  let mockedState;
  let pageInfo;
  let releases;
  let graphqlReleasesResponse;

  const projectPath = 'root/test-project';
  const projectId = 19;

  beforeEach(() => {
    mockedState = {
      ...createState({
        projectId,
        projectPath,
      }),
      featureFlags: {
        graphqlReleaseData: true,
        graphqlReleasesPage: true,
        graphqlMilestoneStats: true,
      },
    };

    pageInfo = parseIntPagination(pageInfoHeadersWithoutPagination);
    releases = convertObjectPropsToCamelCase(originalReleases, { deep: true });
    graphqlReleasesResponse = cloneDeep(originalGraphqlReleasesResponse);
  });

  describe('requestReleases', () => {
    it('should commit REQUEST_RELEASES mutation', done => {
      testAction(requestReleases, null, mockedState, [{ type: types.REQUEST_RELEASES }], [], done);
    });
  });

  describe('fetchReleases', () => {
    describe('success', () => {
      it('dispatches requestReleases and receiveReleasesSuccess', done => {
        jest.spyOn(gqClient, 'query').mockImplementation(({ query, variables }) => {
          expect(query).toBe(allReleasesQuery);
          expect(variables).toEqual({
            fullPath: projectPath,
          });
          return Promise.resolve(graphqlReleasesResponse);
        });

        testAction(
          fetchReleases,
          {},
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              payload: convertGraphQLResponse(graphqlReleasesResponse),
              type: 'receiveReleasesSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      it('dispatches requestReleases and receiveReleasesError', done => {
        jest.spyOn(gqClient, 'query').mockRejectedValue();

        testAction(
          fetchReleases,
          {},
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              type: 'receiveReleasesError',
            },
          ],
          done,
        );
      });
    });

    describe('when the graphqlReleaseData feature flag is disabled', () => {
      beforeEach(() => {
        mockedState.featureFlags.graphqlReleasesPage = false;
      });

      describe('success', () => {
        it('dispatches requestReleases and receiveReleasesSuccess', done => {
          jest.spyOn(api, 'releases').mockImplementation((id, options) => {
            expect(id).toBe(projectId);
            expect(options.page).toBe('1');
            return Promise.resolve({ data: releases, headers: pageInfoHeadersWithoutPagination });
          });

          testAction(
            fetchReleases,
            {},
            mockedState,
            [],
            [
              {
                type: 'requestReleases',
              },
              {
                payload: { data: releases, headers: pageInfoHeadersWithoutPagination },
                type: 'receiveReleasesSuccess',
              },
            ],
            done,
          );
        });

        it('dispatches requestReleases and receiveReleasesSuccess on page two', done => {
          jest.spyOn(api, 'releases').mockImplementation((_, options) => {
            expect(options.page).toBe('2');
            return Promise.resolve({ data: releases, headers: pageInfoHeadersWithoutPagination });
          });

          testAction(
            fetchReleases,
            { page: '2' },
            mockedState,
            [],
            [
              {
                type: 'requestReleases',
              },
              {
                payload: { data: releases, headers: pageInfoHeadersWithoutPagination },
                type: 'receiveReleasesSuccess',
              },
            ],
            done,
          );
        });
      });

      describe('error', () => {
        it('dispatches requestReleases and receiveReleasesError', done => {
          jest.spyOn(api, 'releases').mockReturnValue(Promise.reject());

          testAction(
            fetchReleases,
            {},
            mockedState,
            [],
            [
              {
                type: 'requestReleases',
              },
              {
                type: 'receiveReleasesError',
              },
            ],
            done,
          );
        });
      });
    });
  });

  describe('receiveReleasesSuccess', () => {
    it('should commit RECEIVE_RELEASES_SUCCESS mutation', done => {
      testAction(
        receiveReleasesSuccess,
        { data: releases, headers: pageInfoHeadersWithoutPagination },
        mockedState,
        [{ type: types.RECEIVE_RELEASES_SUCCESS, payload: { pageInfo, data: releases } }],
        [],
        done,
      );
    });
  });

  describe('receiveReleasesError', () => {
    it('should commit RECEIVE_RELEASES_ERROR mutation', done => {
      testAction(
        receiveReleasesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_ERROR }],
        [],
        done,
      );
    });
  });
});

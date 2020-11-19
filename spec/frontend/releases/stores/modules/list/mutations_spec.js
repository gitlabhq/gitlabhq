import { getJSONFixture } from 'helpers/fixtures';
import createState from '~/releases/stores/modules/list/state';
import mutations from '~/releases/stores/modules/list/mutations';
import * as types from '~/releases/stores/modules/list/mutation_types';
import { parseIntPagination, convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { pageInfoHeadersWithoutPagination } from '../../../mock_data';
import { convertAllReleasesGraphQLResponse } from '~/releases/util';

const originalRelease = getJSONFixture('api/releases/release.json');
const originalReleases = [originalRelease];

const graphqlReleasesResponse = getJSONFixture(
  'graphql/releases/queries/all_releases.query.graphql.json',
);

describe('Releases Store Mutations', () => {
  let stateCopy;
  let restPageInfo;
  let graphQlPageInfo;
  let releases;

  beforeEach(() => {
    stateCopy = createState({});
    restPageInfo = parseIntPagination(pageInfoHeadersWithoutPagination);
    graphQlPageInfo = convertAllReleasesGraphQLResponse(graphqlReleasesResponse).paginationInfo;
    releases = convertObjectPropsToCamelCase(originalReleases, { deep: true });
  });

  describe('REQUEST_RELEASES', () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_RELEASES](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_RELEASES_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_RELEASES_SUCCESS](stateCopy, {
        restPageInfo,
        graphQlPageInfo,
        data: releases,
      });
    });

    it('sets is loading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('sets hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('sets data', () => {
      expect(stateCopy.releases).toEqual(releases);
    });

    it('sets restPageInfo', () => {
      expect(stateCopy.restPageInfo).toEqual(restPageInfo);
    });

    it('sets graphQlPageInfo', () => {
      expect(stateCopy.graphQlPageInfo).toEqual(graphQlPageInfo);
    });
  });

  describe('RECEIVE_RELEASES_ERROR', () => {
    it('resets data', () => {
      mutations[types.RECEIVE_RELEASES_SUCCESS](stateCopy, {
        restPageInfo,
        graphQlPageInfo,
        data: releases,
      });

      mutations[types.RECEIVE_RELEASES_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.releases).toEqual([]);
      expect(stateCopy.restPageInfo).toEqual({});
      expect(stateCopy.graphQlPageInfo).toEqual({});
    });
  });

  describe('SET_SORTING', () => {
    it('should merge the sorting object with sort value', () => {
      mutations[types.SET_SORTING](stateCopy, { sort: 'asc' });
      expect(stateCopy.sorting).toEqual({ ...stateCopy.sorting, sort: 'asc' });
    });

    it('should merge the sorting object with order_by value', () => {
      mutations[types.SET_SORTING](stateCopy, { orderBy: 'created_at' });
      expect(stateCopy.sorting).toEqual({ ...stateCopy.sorting, orderBy: 'created_at' });
    });
  });
});

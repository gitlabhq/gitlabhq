import { getJSONFixture } from 'helpers/fixtures';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from '~/releases/stores/modules/index/mutation_types';
import mutations from '~/releases/stores/modules/index/mutations';
import createState from '~/releases/stores/modules/index/state';
import { convertAllReleasesGraphQLResponse } from '~/releases/util';

const originalRelease = getJSONFixture('api/releases/release.json');
const originalReleases = [originalRelease];

const graphqlReleasesResponse = getJSONFixture(
  'graphql/releases/graphql/queries/all_releases.query.graphql.json',
);

describe('Releases Store Mutations', () => {
  let stateCopy;
  let pageInfo;
  let releases;

  beforeEach(() => {
    stateCopy = createState({});
    pageInfo = convertAllReleasesGraphQLResponse(graphqlReleasesResponse).paginationInfo;
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
        pageInfo,
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

    it('sets pageInfo', () => {
      expect(stateCopy.pageInfo).toEqual(pageInfo);
    });
  });

  describe('RECEIVE_RELEASES_ERROR', () => {
    it('resets data', () => {
      mutations[types.RECEIVE_RELEASES_SUCCESS](stateCopy, {
        pageInfo,
        data: releases,
      });

      mutations[types.RECEIVE_RELEASES_ERROR](stateCopy);

      expect(stateCopy.isLoading).toEqual(false);
      expect(stateCopy.releases).toEqual([]);
      expect(stateCopy.pageInfo).toEqual({});
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

/* eslint-disable jest/valid-describe */
/*
 * ESLint disable directive ↑ can be removed once
 * https://github.com/jest-community/eslint-plugin-jest/issues/203
 * is resolved
 */

import createState from '~/releases/stores/modules/detail/state';
import mutations from '~/releases/stores/modules/detail/mutations';
import * as types from '~/releases/stores/modules/detail/mutation_types';
import { release } from '../../../mock_data';

describe('Release detail mutations', () => {
  let state;
  let releaseClone;

  beforeEach(() => {
    state = createState({
      projectId: '18',
      tagName: 'v1.3',
      releasesPagePath: 'path/to/releases/page',
      markdownDocsPath: 'path/to/markdown/docs',
      markdownPreviewPath: 'path/to/markdown/preview',
      updateReleaseApiDocsPath: 'path/to/api/docs',
    });
    releaseClone = JSON.parse(JSON.stringify(release));
  });

  describe(types.REQUEST_RELEASE, () => {
    it('set state.isFetchingRelease to true', () => {
      mutations[types.REQUEST_RELEASE](state);

      expect(state.isFetchingRelease).toEqual(true);
    });
  });

  describe(types.RECEIVE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_RELEASE_SUCCESS](state, releaseClone);

      expect(state.fetchError).toEqual(undefined);

      expect(state.isFetchingRelease).toEqual(false);

      expect(state.release).toEqual(releaseClone);
    });
  });

  describe(types.RECEIVE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_RELEASE_ERROR](state, error);

      expect(state.isFetchingRelease).toEqual(false);

      expect(state.release).toBeUndefined();

      expect(state.fetchError).toEqual(error);
    });
  });

  describe(types.UPDATE_RELEASE_TITLE, () => {
    it("updates the release's title", () => {
      state.release = releaseClone;
      const newTitle = 'The new release title';
      mutations[types.UPDATE_RELEASE_TITLE](state, newTitle);

      expect(state.release.name).toEqual(newTitle);
    });
  });

  describe(types.UPDATE_RELEASE_NOTES, () => {
    it("updates the release's notes", () => {
      state.release = releaseClone;
      const newNotes = 'The new release notes';
      mutations[types.UPDATE_RELEASE_NOTES](state, newNotes);

      expect(state.release.description).toEqual(newNotes);
    });
  });

  describe(types.REQUEST_UPDATE_RELEASE, () => {
    it('set state.isUpdatingRelease to true', () => {
      mutations[types.REQUEST_UPDATE_RELEASE](state);

      expect(state.isUpdatingRelease).toEqual(true);
    });
  });

  describe(types.RECEIVE_UPDATE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_UPDATE_RELEASE_SUCCESS](state, releaseClone);

      expect(state.updateError).toEqual(undefined);

      expect(state.isUpdatingRelease).toEqual(false);
    });
  });

  describe(types.RECEIVE_UPDATE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_UPDATE_RELEASE_ERROR](state, error);

      expect(state.isUpdatingRelease).toEqual(false);

      expect(state.updateError).toEqual(error);
    });
  });
});

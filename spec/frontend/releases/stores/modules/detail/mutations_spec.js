/* eslint-disable jest/valid-describe */
/*
 * ESLint disable directive ↑ can be removed once
 * https://github.com/jest-community/eslint-plugin-jest/issues/203
 * is resolved
 */

import state from '~/releases/stores/modules/detail/state';
import mutations from '~/releases/stores/modules/detail/mutations';
import * as types from '~/releases/stores/modules/detail/mutation_types';
import { release } from '../../../mock_data';

describe('Release detail mutations', () => {
  let stateClone;
  let releaseClone;

  beforeEach(() => {
    stateClone = state();
    releaseClone = JSON.parse(JSON.stringify(release));
  });

  describe(types.SET_INITIAL_STATE, () => {
    it('populates the state with initial values', () => {
      const initialState = {
        projectId: '18',
        tagName: 'v1.3',
        releasesPagePath: 'path/to/releases/page',
        markdownDocsPath: 'path/to/markdown/docs',
        markdownPreviewPath: 'path/to/markdown/preview',
      };

      mutations[types.SET_INITIAL_STATE](stateClone, initialState);

      expect(stateClone).toEqual(expect.objectContaining(initialState));
    });
  });

  describe(types.REQUEST_RELEASE, () => {
    it('set state.isFetchingRelease to true', () => {
      mutations[types.REQUEST_RELEASE](stateClone);

      expect(stateClone.isFetchingRelease).toEqual(true);
    });
  });

  describe(types.RECEIVE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_RELEASE_SUCCESS](stateClone, releaseClone);

      expect(stateClone.fetchError).toEqual(undefined);

      expect(stateClone.isFetchingRelease).toEqual(false);

      expect(stateClone.release).toEqual(releaseClone);
    });
  });

  describe(types.RECEIVE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_RELEASE_ERROR](stateClone, error);

      expect(stateClone.isFetchingRelease).toEqual(false);

      expect(stateClone.release).toBeUndefined();

      expect(stateClone.fetchError).toEqual(error);
    });
  });

  describe(types.UPDATE_RELEASE_TITLE, () => {
    it("updates the release's title", () => {
      stateClone.release = releaseClone;
      const newTitle = 'The new release title';
      mutations[types.UPDATE_RELEASE_TITLE](stateClone, newTitle);

      expect(stateClone.release.name).toEqual(newTitle);
    });
  });

  describe(types.UPDATE_RELEASE_NOTES, () => {
    it("updates the release's notes", () => {
      stateClone.release = releaseClone;
      const newNotes = 'The new release notes';
      mutations[types.UPDATE_RELEASE_NOTES](stateClone, newNotes);

      expect(stateClone.release.description).toEqual(newNotes);
    });
  });

  describe(types.REQUEST_UPDATE_RELEASE, () => {
    it('set state.isUpdatingRelease to true', () => {
      mutations[types.REQUEST_UPDATE_RELEASE](stateClone);

      expect(stateClone.isUpdatingRelease).toEqual(true);
    });
  });

  describe(types.RECEIVE_UPDATE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_UPDATE_RELEASE_SUCCESS](stateClone, releaseClone);

      expect(stateClone.updateError).toEqual(undefined);

      expect(stateClone.isUpdatingRelease).toEqual(false);
    });
  });

  describe(types.RECEIVE_UPDATE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_UPDATE_RELEASE_ERROR](stateClone, error);

      expect(stateClone.isUpdatingRelease).toEqual(false);

      expect(stateClone.updateError).toEqual(error);
    });
  });
});

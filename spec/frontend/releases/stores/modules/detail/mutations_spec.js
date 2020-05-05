import createState from '~/releases/stores/modules/detail/state';
import mutations from '~/releases/stores/modules/detail/mutations';
import * as types from '~/releases/stores/modules/detail/mutation_types';
import { release as originalRelease } from '../../../mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('Release detail mutations', () => {
  let state;
  let release;

  beforeEach(() => {
    state = createState({
      projectId: '18',
      tagName: 'v1.3',
      releasesPagePath: 'path/to/releases/page',
      markdownDocsPath: 'path/to/markdown/docs',
      markdownPreviewPath: 'path/to/markdown/preview',
      updateReleaseApiDocsPath: 'path/to/api/docs',
    });
    release = convertObjectPropsToCamelCase(originalRelease);
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.REQUEST_RELEASE, () => {
    it('set state.isFetchingRelease to true', () => {
      mutations[types.REQUEST_RELEASE](state);

      expect(state.isFetchingRelease).toEqual(true);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.RECEIVE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_RELEASE_SUCCESS](state, release);

      expect(state.fetchError).toEqual(undefined);

      expect(state.isFetchingRelease).toEqual(false);

      expect(state.release).toEqual(release);

      expect(state.originalRelease).toEqual(release);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.RECEIVE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_RELEASE_ERROR](state, error);

      expect(state.isFetchingRelease).toEqual(false);

      expect(state.release).toBeUndefined();

      expect(state.fetchError).toEqual(error);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.UPDATE_RELEASE_TITLE, () => {
    it("updates the release's title", () => {
      state.release = release;
      const newTitle = 'The new release title';
      mutations[types.UPDATE_RELEASE_TITLE](state, newTitle);

      expect(state.release.name).toEqual(newTitle);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.UPDATE_RELEASE_NOTES, () => {
    it("updates the release's notes", () => {
      state.release = release;
      const newNotes = 'The new release notes';
      mutations[types.UPDATE_RELEASE_NOTES](state, newNotes);

      expect(state.release.description).toEqual(newNotes);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.REQUEST_UPDATE_RELEASE, () => {
    it('set state.isUpdatingRelease to true', () => {
      mutations[types.REQUEST_UPDATE_RELEASE](state);

      expect(state.isUpdatingRelease).toEqual(true);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.RECEIVE_UPDATE_RELEASE_SUCCESS, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_UPDATE_RELEASE_SUCCESS](state, release);

      expect(state.updateError).toEqual(undefined);

      expect(state.isUpdatingRelease).toEqual(false);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.RECEIVE_UPDATE_RELEASE_ERROR, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_UPDATE_RELEASE_ERROR](state, error);

      expect(state.isUpdatingRelease).toEqual(false);

      expect(state.updateError).toEqual(error);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.ADD_EMPTY_ASSET_LINK, () => {
    it('adds a new, empty link object to the release', () => {
      state.release = release;

      const linksBefore = [...state.release.assets.links];

      mutations[types.ADD_EMPTY_ASSET_LINK](state);

      expect(state.release.assets.links).toEqual([
        ...linksBefore,
        {
          id: expect.stringMatching(/^new-link-/),
          url: '',
          name: '',
        },
      ]);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.UPDATE_ASSET_LINK_URL, () => {
    it('updates an asset link with a new URL', () => {
      state.release = release;

      const newUrl = 'https://example.com/updated/url';

      mutations[types.UPDATE_ASSET_LINK_URL](state, {
        linkIdToUpdate: state.release.assets.links[0].id,
        newUrl,
      });

      expect(state.release.assets.links[0].url).toEqual(newUrl);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.UPDATE_ASSET_LINK_NAME, () => {
    it('updates an asset link with a new name', () => {
      state.release = release;

      const newName = 'Updated Link';

      mutations[types.UPDATE_ASSET_LINK_NAME](state, {
        linkIdToUpdate: state.release.assets.links[0].id,
        newName,
      });

      expect(state.release.assets.links[0].name).toEqual(newName);
    });
  });

  // eslint-disable-next-line jest/valid-describe
  describe(types.REMOVE_ASSET_LINK, () => {
    it('removes an asset link from the release', () => {
      state.release = release;

      const linkToRemove = state.release.assets.links[0];

      mutations[types.REMOVE_ASSET_LINK](state, linkToRemove.id);

      expect(state.release.assets.links).not.toContainEqual(linkToRemove);
    });
  });
});

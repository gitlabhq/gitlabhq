import { getJSONFixture } from 'helpers/fixtures';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { ASSET_LINK_TYPE, DEFAULT_ASSET_LINK_TYPE } from '~/releases/constants';
import * as types from '~/releases/stores/modules/edit_new/mutation_types';
import mutations from '~/releases/stores/modules/edit_new/mutations';
import createState from '~/releases/stores/modules/edit_new/state';

const originalRelease = getJSONFixture('api/releases/release.json');

describe('Release edit/new mutations', () => {
  let state;
  let release;

  beforeEach(() => {
    state = createState({
      projectId: '18',
      tagName: 'v1.3',
      releasesPagePath: 'path/to/releases/page',
      markdownDocsPath: 'path/to/markdown/docs',
      markdownPreviewPath: 'path/to/markdown/preview',
    });
    release = convertObjectPropsToCamelCase(originalRelease);
  });

  describe(`${types.INITIALIZE_EMPTY_RELEASE}`, () => {
    it('set state.release to an empty release object', () => {
      mutations[types.INITIALIZE_EMPTY_RELEASE](state);

      expect(state.release).toEqual({
        tagName: null,
        name: '',
        description: '',
        milestones: [],
        groupMilestones: [],
        assets: {
          links: [],
        },
      });
    });
  });

  describe(`${types.REQUEST_RELEASE}`, () => {
    it('set state.isFetchingRelease to true', () => {
      mutations[types.REQUEST_RELEASE](state);

      expect(state.isFetchingRelease).toBe(true);
    });
  });

  describe(`${types.RECEIVE_RELEASE_SUCCESS}`, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_RELEASE_SUCCESS](state, release);

      expect(state.fetchError).toBeUndefined();

      expect(state.isFetchingRelease).toBe(false);

      expect(state.release).toEqual(release);

      expect(state.originalRelease).toEqual(release);
    });
  });

  describe(`${types.RECEIVE_RELEASE_ERROR}`, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_RELEASE_ERROR](state, error);

      expect(state.isFetchingRelease).toBe(false);

      expect(state.release).toBeUndefined();

      expect(state.fetchError).toEqual(error);
    });
  });

  describe(`${types.UPDATE_RELEASE_TAG_NAME}`, () => {
    it("updates the release's tag name", () => {
      state.release = release;
      const newTag = 'updated-tag-name';
      mutations[types.UPDATE_RELEASE_TAG_NAME](state, newTag);

      expect(state.release.tagName).toBe(newTag);
    });
  });

  describe(`${types.UPDATE_CREATE_FROM}`, () => {
    it('updates the ref that the ref will be created from', () => {
      state.createFrom = 'main';
      const newRef = 'my-feature-branch';
      mutations[types.UPDATE_CREATE_FROM](state, newRef);

      expect(state.createFrom).toBe(newRef);
    });
  });

  describe(`${types.UPDATE_RELEASE_TITLE}`, () => {
    it("updates the release's title", () => {
      state.release = release;
      const newTitle = 'The new release title';
      mutations[types.UPDATE_RELEASE_TITLE](state, newTitle);

      expect(state.release.name).toBe(newTitle);
    });
  });

  describe(`${types.UPDATE_RELEASE_NOTES}`, () => {
    it("updates the release's notes", () => {
      state.release = release;
      const newNotes = 'The new release notes';
      mutations[types.UPDATE_RELEASE_NOTES](state, newNotes);

      expect(state.release.description).toBe(newNotes);
    });
  });

  describe(`${types.UPDATE_RELEASE_MILESTONES}`, () => {
    it("updates the release's milestones", () => {
      state.release = release;
      const newReleaseMilestones = ['v0.0', 'v0.1'];
      mutations[types.UPDATE_RELEASE_MILESTONES](state, newReleaseMilestones);

      expect(state.release.milestones).toBe(newReleaseMilestones);
    });
  });

  describe(`${types.UPDATE_RELEASE_GROUP_MILESTONES}`, () => {
    it("updates the release's group milestones", () => {
      state.release = release;
      const newReleaseGroupMilestones = ['v0.0', 'v0.1'];
      mutations[types.UPDATE_RELEASE_GROUP_MILESTONES](state, newReleaseGroupMilestones);

      expect(state.release.groupMilestones).toBe(newReleaseGroupMilestones);
    });
  });

  describe(`${types.REQUEST_SAVE_RELEASE}`, () => {
    it('set state.isUpdatingRelease to true', () => {
      mutations[types.REQUEST_SAVE_RELEASE](state);

      expect(state.isUpdatingRelease).toBe(true);
    });
  });

  describe(`${types.RECEIVE_SAVE_RELEASE_SUCCESS}`, () => {
    it('handles a successful response from the server', () => {
      mutations[types.RECEIVE_SAVE_RELEASE_SUCCESS](state, release);

      expect(state.updateError).toBeUndefined();

      expect(state.isUpdatingRelease).toBe(false);
    });
  });

  describe(`${types.RECEIVE_SAVE_RELEASE_ERROR}`, () => {
    it('handles an unsuccessful response from the server', () => {
      const error = { message: 'An error occurred!' };
      mutations[types.RECEIVE_SAVE_RELEASE_ERROR](state, error);

      expect(state.isUpdatingRelease).toBe(false);

      expect(state.updateError).toEqual(error);
    });
  });

  describe(`${types.ADD_EMPTY_ASSET_LINK}`, () => {
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
          linkType: DEFAULT_ASSET_LINK_TYPE,
        },
      ]);
    });
  });

  describe(`${types.UPDATE_ASSET_LINK_URL}`, () => {
    it('updates an asset link with a new URL', () => {
      state.release = release;

      const newUrl = 'https://example.com/updated/url';

      mutations[types.UPDATE_ASSET_LINK_URL](state, {
        linkIdToUpdate: state.release.assets.links[0].id,
        newUrl,
      });

      expect(state.release.assets.links[0].url).toBe(newUrl);
    });
  });

  describe(`${types.UPDATE_ASSET_LINK_NAME}`, () => {
    it('updates an asset link with a new name', () => {
      state.release = release;

      const newName = 'Updated Link';

      mutations[types.UPDATE_ASSET_LINK_NAME](state, {
        linkIdToUpdate: state.release.assets.links[0].id,
        newName,
      });

      expect(state.release.assets.links[0].name).toBe(newName);
    });
  });

  describe(`${types.UPDATE_ASSET_LINK_TYPE}`, () => {
    it('updates an asset link with a new type', () => {
      state.release = release;

      const newType = ASSET_LINK_TYPE.RUNBOOK;

      mutations[types.UPDATE_ASSET_LINK_TYPE](state, {
        linkIdToUpdate: state.release.assets.links[0].id,
        newType,
      });

      expect(state.release.assets.links[0].linkType).toBe(newType);
    });
  });

  describe(`${types.REMOVE_ASSET_LINK}`, () => {
    it('removes an asset link from the release', () => {
      state.release = release;

      const linkToRemove = state.release.assets.links[0];

      mutations[types.REMOVE_ASSET_LINK](state, linkToRemove.id);

      expect(state.release.assets.links).not.toContainEqual(linkToRemove);
    });
  });
});

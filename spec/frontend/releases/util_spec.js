import { releaseToApiJson, apiJsonToRelease } from '~/releases/util';

describe('releases/util.js', () => {
  describe('releaseToApiJson', () => {
    it('converts a release JavaScript object into JSON that the Release API can accept', () => {
      const release = {
        tagName: 'tag-name',
        name: 'Release name',
        description: 'Release description',
        milestones: [{ id: 1, title: '13.2' }, { id: 2, title: '13.3' }],
        assets: {
          links: [{ url: 'https://gitlab.example.com/link', linkType: 'other' }],
        },
      };

      const expectedJson = {
        tag_name: 'tag-name',
        ref: null,
        name: 'Release name',
        description: 'Release description',
        milestones: ['13.2', '13.3'],
        assets: {
          links: [{ url: 'https://gitlab.example.com/link', link_type: 'other' }],
        },
      };

      expect(releaseToApiJson(release)).toEqual(expectedJson);
    });

    describe('when createFrom is provided', () => {
      it('adds the provided createFrom ref to the JSON as a "ref" property', () => {
        const createFrom = 'main';

        const release = {};

        const expectedJson = {
          ref: createFrom,
        };

        expect(releaseToApiJson(release, createFrom)).toMatchObject(expectedJson);
      });
    });

    describe('when release.milestones is falsy', () => {
      it('includes a "milestone" property in the returned result as an empty array', () => {
        const release = {};

        const expectedJson = {
          milestones: [],
        };

        expect(releaseToApiJson(release)).toMatchObject(expectedJson);
      });
    });
  });

  describe('apiJsonToRelease', () => {
    it('converts JSON received from the Release API into an object usable by the Vue application', () => {
      const json = {
        tag_name: 'tag-name',
        assets: {
          links: [
            {
              link_type: 'other',
            },
          ],
        },
      };

      const expectedRelease = {
        tagName: 'tag-name',
        assets: {
          links: [
            {
              linkType: 'other',
            },
          ],
        },
        milestones: [],
      };

      expect(apiJsonToRelease(json)).toEqual(expectedRelease);
    });
  });
});

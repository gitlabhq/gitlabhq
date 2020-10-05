import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import { releaseToApiJson, apiJsonToRelease, convertGraphQLResponse } from '~/releases/util';

const originalGraphqlReleasesResponse = getJSONFixture(
  'graphql/releases/queries/all_releases.query.graphql.json',
);

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

    describe('release.name', () => {
      it.each`
        input                 | output
        ${null}               | ${null}
        ${''}                 | ${null}
        ${' \t\n\r\n'}        | ${null}
        ${'  Release name  '} | ${'Release name'}
      `('converts a name like `$input` to `$output`', ({ input, output }) => {
        const release = { name: input };

        const expectedJson = {
          name: output,
        };

        expect(releaseToApiJson(release)).toMatchObject(expectedJson);
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

  describe('convertGraphQLResponse', () => {
    let graphqlReleasesResponse;
    let converted;

    beforeEach(() => {
      graphqlReleasesResponse = cloneDeep(originalGraphqlReleasesResponse);
      converted = convertGraphQLResponse(graphqlReleasesResponse);
    });

    it('matches snapshot', () => {
      expect(converted).toMatchSnapshot();
    });

    describe('assets', () => {
      it("handles asset links that don't have a linkType", () => {
        expect(converted.data[0].assets.links[0].linkType).not.toBeUndefined();

        delete graphqlReleasesResponse.data.project.releases.nodes[0].assets.links.nodes[0]
          .linkType;

        converted = convertGraphQLResponse(graphqlReleasesResponse);

        expect(converted.data[0].assets.links[0].linkType).toBeUndefined();
      });
    });

    describe('_links', () => {
      it("handles releases that don't have any links", () => {
        expect(converted.data[0]._links.selfUrl).not.toBeUndefined();

        delete graphqlReleasesResponse.data.project.releases.nodes[0].links;

        converted = convertGraphQLResponse(graphqlReleasesResponse);

        expect(converted.data[0]._links.selfUrl).toBeUndefined();
      });
    });

    describe('commit', () => {
      it("handles releases that don't have any commit info", () => {
        expect(converted.data[0].commit).not.toBeUndefined();

        delete graphqlReleasesResponse.data.project.releases.nodes[0].commit;

        converted = convertGraphQLResponse(graphqlReleasesResponse);

        expect(converted.data[0].commit).toBeUndefined();
      });
    });
  });
});

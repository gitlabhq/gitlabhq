import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import {
  releaseToApiJson,
  apiJsonToRelease,
  convertGraphQLRelease,
  convertAllReleasesGraphQLResponse,
  convertOneReleaseGraphQLResponse,
} from '~/releases/util';

const originalAllReleasesQueryResponse = getJSONFixture(
  'graphql/releases/queries/all_releases.query.graphql.json',
);
const originalOneReleaseQueryResponse = getJSONFixture(
  'graphql/releases/queries/one_release.query.graphql.json',
);

describe('releases/util.js', () => {
  describe('releaseToApiJson', () => {
    it('converts a release JavaScript object into JSON that the Release API can accept', () => {
      const release = {
        tagName: 'tag-name',
        name: 'Release name',
        description: 'Release description',
        milestones: ['13.2', '13.3'],
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

    describe('when milestones contains full milestone objects', () => {
      it('converts the milestone objects into titles', () => {
        const release = {
          milestones: [{ title: '13.2' }, { title: '13.3' }, '13.4'],
        };

        const expectedJson = { milestones: ['13.2', '13.3', '13.4'] };

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

  describe('convertGraphQLRelease', () => {
    let releaseFromResponse;
    let convertedRelease;

    beforeEach(() => {
      releaseFromResponse = cloneDeep(originalOneReleaseQueryResponse).data.project.release;
      convertedRelease = convertGraphQLRelease(releaseFromResponse);
    });

    describe('assets', () => {
      it("handles asset links that don't have a linkType", () => {
        expect(convertedRelease.assets.links[0].linkType).not.toBeUndefined();

        delete releaseFromResponse.assets.links.nodes[0].linkType;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.assets.links[0].linkType).toBeUndefined();
      });
    });

    describe('_links', () => {
      it("handles releases that don't have any links", () => {
        expect(convertedRelease._links.selfUrl).not.toBeUndefined();

        delete releaseFromResponse.links;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease._links.selfUrl).toBeUndefined();
      });
    });

    describe('commit', () => {
      it("handles releases that don't have any commit info", () => {
        expect(convertedRelease.commit).not.toBeUndefined();

        delete releaseFromResponse.commit;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.commit).toBeUndefined();
      });
    });
  });

  describe('convertAllReleasesGraphQLResponse', () => {
    it('matches snapshot', () => {
      expect(convertAllReleasesGraphQLResponse(originalAllReleasesQueryResponse)).toMatchSnapshot();
    });
  });

  describe('convertOneReleaseGraphQLResponse', () => {
    it('matches snapshot', () => {
      expect(convertOneReleaseGraphQLResponse(originalOneReleaseQueryResponse)).toMatchSnapshot();
    });
  });
});

import { cloneDeep } from 'lodash';
import { getJSONFixture } from 'helpers/fixtures';
import {
  convertGraphQLRelease,
  convertAllReleasesGraphQLResponse,
  convertOneReleaseGraphQLResponse,
} from '~/releases/util';

const originalAllReleasesQueryResponse = getJSONFixture(
  'graphql/releases/graphql/queries/all_releases.query.graphql.json',
);
const originalOneReleaseQueryResponse = getJSONFixture(
  'graphql/releases/graphql/queries/one_release.query.graphql.json',
);
const originalOneReleaseForEditingQueryResponse = getJSONFixture(
  'graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json',
);

describe('releases/util.js', () => {
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

      it('handles assets that have no links', () => {
        expect(convertedRelease.assets.links[0]).not.toBeUndefined();

        delete releaseFromResponse.assets.links;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.assets.links).toEqual([]);
      });

      it('handles assets that have no sources', () => {
        expect(convertedRelease.assets.sources[0]).not.toBeUndefined();

        delete releaseFromResponse.assets.sources;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.assets.sources).toEqual([]);
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

    describe('milestones', () => {
      it("handles releases that don't have any milestone stats", () => {
        expect(convertedRelease.milestones[0].issueStats).not.toBeUndefined();

        releaseFromResponse.milestones.nodes = releaseFromResponse.milestones.nodes.map((n) => ({
          ...n,
          stats: undefined,
        }));

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.milestones[0].issueStats).toEqual({});
      });
    });

    describe('evidences', () => {
      it("handles releases that don't have any evidences", () => {
        expect(convertedRelease.evidences).not.toBeUndefined();

        delete releaseFromResponse.evidences;

        convertedRelease = convertGraphQLRelease(releaseFromResponse);

        expect(convertedRelease.evidences).toEqual([]);
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

  describe('convertOneReleaseForEditingGraphQLResponse', () => {
    it('matches snapshot', () => {
      expect(
        convertOneReleaseGraphQLResponse(originalOneReleaseForEditingQueryResponse),
      ).toMatchSnapshot();
    });
  });
});

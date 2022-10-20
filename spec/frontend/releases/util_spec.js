import { cloneDeep } from 'lodash';
import originalAllReleasesQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/all_releases.query.graphql.json';
import originalOneReleaseQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release.query.graphql.json';
import originalOneReleaseForEditingQueryResponse from 'test_fixtures/graphql/releases/graphql/queries/one_release_for_editing.query.graphql.json';
import {
  convertGraphQLRelease,
  convertAllReleasesGraphQLResponse,
  convertOneReleaseGraphQLResponse,
} from '~/releases/util';

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
      expect(convertAllReleasesGraphQLResponse(originalAllReleasesQueryResponse)).toMatchSnapshot({
        data: [
          {
            author: {
              id: expect.any(String),
            },
          },
          {
            author: {
              id: expect.any(String),
            },
            evidences: [
              {
                id: expect.any(String),
                filepath: expect.any(String),
              },
            ],
          },
        ],
        paginationInfo: {
          startCursor: expect.any(String),
          endCursor: expect.any(String),
        },
      });
    });
  });

  describe('convertOneReleaseGraphQLResponse', () => {
    it('matches snapshot', () => {
      expect(convertOneReleaseGraphQLResponse(originalOneReleaseQueryResponse)).toMatchSnapshot({
        data: {
          author: {
            id: expect.any(String),
          },
          evidences: [
            {
              id: expect.any(String),
              filepath: expect.any(String),
            },
          ],
        },
      });
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

import gql from 'graphql-tag';
import { defaultClient } from '~/analytics/shared/graphql/client';

const labelsQuery = gql`
  query groupLabels($fullPath: ID!, $searchTerm: String) {
    group(fullPath: $fullPath) {
      id
      labels(searchTerm: $searchTerm) {
        nodes {
          id
          title
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`;

const variables = { fullPath: 'group/path', searchTerm: '' };

const label = (n) => ({
  __typename: 'Label',
  id: `gid://gitlab/GroupLabel/${n}`,
  title: `Label ${n}`,
});

const writeLabels = (nodes) =>
  defaultClient.cache.writeQuery({
    query: labelsQuery,
    variables,
    data: {
      group: {
        __typename: 'Group',
        id: 'gid://gitlab/Group/1',
        labels: {
          __typename: 'LabelConnection',
          nodes,
          pageInfo: { __typename: 'PageInfo', hasNextPage: false, endCursor: null },
        },
      },
    },
  });

const readLabelIds = () =>
  defaultClient.cache
    .readQuery({ query: labelsQuery, variables })
    .group.labels.nodes.map((node) => node.id);

describe('analytics shared GraphQL client', () => {
  afterEach(() => defaultClient.clearStore());

  describe('LabelConnection nodes merge', () => {
    it('appends labels across non-overlapping pages', () => {
      writeLabels([label(1), label(2)]);
      writeLabels([label(3), label(4)]);

      expect(readLabelIds()).toEqual([
        'gid://gitlab/GroupLabel/1',
        'gid://gitlab/GroupLabel/2',
        'gid://gitlab/GroupLabel/3',
        'gid://gitlab/GroupLabel/4',
      ]);
    });

    it('dedupes labels by id when overlapping pages are merged into the shared entry', () => {
      writeLabels([label(1), label(2)]);
      writeLabels([label(2), label(3)]);

      expect(readLabelIds()).toEqual([
        'gid://gitlab/GroupLabel/1',
        'gid://gitlab/GroupLabel/2',
        'gid://gitlab/GroupLabel/3',
      ]);
    });
  });
});

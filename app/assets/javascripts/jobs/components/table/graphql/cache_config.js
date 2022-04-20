import { isEqual } from 'lodash';

export default {
  typePolicies: {
    Project: {
      fields: {
        jobs: {
          keyArgs: false,
        },
      },
    },
    CiJobConnection: {
      merge(existing = {}, incoming, { args = {} }) {
        let nodes;

        const areNodesEqual = isEqual(existing.nodes, incoming.nodes);
        const statuses = Array.isArray(args.statuses) ? [...args.statuses] : args.statuses;
        const { pageInfo } = incoming;

        if (Object.keys(existing).length !== 0 && isEqual(existing?.statuses, args?.statuses)) {
          if (areNodesEqual) {
            if (incoming.pageInfo.hasNextPage) {
              nodes = [...existing.nodes, ...incoming.nodes];
            } else {
              nodes = [...incoming.nodes];
            }
          } else {
            if (!existing.pageInfo?.hasNextPage) {
              nodes = [...incoming.nodes];

              return {
                nodes,
                statuses,
                pageInfo,
                count: incoming.count,
              };
            }

            nodes = [...existing.nodes, ...incoming.nodes];
          }
        } else {
          nodes = [...incoming.nodes];
        }

        return {
          nodes,
          statuses,
          pageInfo,
          count: incoming.count,
        };
      },
    },
  },
};

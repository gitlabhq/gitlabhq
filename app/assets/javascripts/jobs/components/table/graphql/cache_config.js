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

        if (Object.keys(existing).length !== 0 && isEqual(existing?.statuses, args?.statuses)) {
          nodes = [...existing.nodes, ...incoming.nodes];
        } else {
          nodes = [...incoming.nodes];
        }

        return {
          nodes,
          statuses: Array.isArray(args.statuses) ? [...args.statuses] : args.statuses,
        };
      },
    },
  },
};

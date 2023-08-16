import { baseQueries, baseMutations } from './resolvers/base';
import kubernetesQueries from './resolvers/kubernetes';
import fluxQueries from './resolvers/flux';

export const resolvers = (endpoint) => ({
  Query: {
    ...baseQueries(endpoint),
    ...kubernetesQueries,
    ...fluxQueries,
  },
  Mutation: {
    ...baseMutations,
  },
});

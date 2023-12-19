import kubernetesQueries from './resolvers/kubernetes';

export const resolvers = {
  Query: {
    ...kubernetesQueries,
  },
};

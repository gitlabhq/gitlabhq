import createGqClient, { fetchPolicies } from '~/lib/graphql';

export default createGqClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
  },
);

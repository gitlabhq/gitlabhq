import '~/webpack';

import { gql } from '@apollo/client';
import { GraphiQL } from 'graphiql';
/* eslint-disable no-restricted-imports */
import React from 'react';
import { createRoot } from 'react-dom/client';
/* eslint-enable no-restricted-imports */
import createDefaultClient, { fetchPolicies } from '~/lib/graphql';

const apolloClient = createDefaultClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
    cacheConfig: { addTypename: false, typePolicies: {}, possibleTypes: {} },
  },
);

const graphiqlContainer = document.getElementById('graphiql-container');

function apolloFetcher(graphQLParams) {
  return apolloClient.subscribe({
    query: gql(graphQLParams.query),
    variables: graphQLParams.variables,
    operationName: graphQLParams.operationName,
  });
}

createRoot(graphiqlContainer).render(React.createElement(GraphiQL, { fetcher: apolloFetcher }));

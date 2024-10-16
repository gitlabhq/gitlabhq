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
  let query = gql(graphQLParams.query);

  /*
    GraphiQL allows multiple named operations to be declared in the editor.
    When the user clicks execute, they are prompted to select one of the operations.
    We must filter the query to only contain the selected operation so we execute the correct query
    and avoid an `Ambiguous GraphQL document: contains 2 operations` error.
  */
  if (graphQLParams.operationName) {
    query = {
      ...query,
      definitions: query.definitions.filter((definition) => {
        return (
          definition.kind !== 'OperationDefinition' ||
          definition.name.value === graphQLParams.operationName
        );
      }),
    };
  }

  return apolloClient.subscribe({
    query,
    variables: graphQLParams.variables,
    operationName: graphQLParams.operationName,
  });
}

createRoot(graphiqlContainer).render(React.createElement(GraphiQL, { fetcher: apolloFetcher }));

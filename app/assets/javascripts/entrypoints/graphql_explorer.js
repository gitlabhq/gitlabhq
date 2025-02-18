import '~/webpack';

import gitlabLogo from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?raw';
import { gql } from '@apollo/client';
import { GraphiQL } from 'graphiql';
/* eslint-disable no-restricted-imports */
import React from 'react';
import { createRoot } from 'react-dom/client';
import { DOCS_URL_IN_EE_DIR } from 'jh_else_ce/lib/utils/url_utility';
/* eslint-enable no-restricted-imports */
import createDefaultClient, { fetchPolicies } from '~/lib/graphql';

const apolloClient = createDefaultClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
    cacheConfig: { addTypename: false, typePolicies: {}, possibleTypes: {} },
  },
);

const defaultQuery = `# Welcome to GraphQL explorer (GraphiQL)
#
# Full documentation: ${DOCS_URL_IN_EE_DIR}/api/graphql
#
# GraphQL explorer is an in-browser tool for writing, validating, and
# testing GraphQL queries.
#
# Type queries into this side of the screen, and you will see intelligent
# typeaheads aware of the current GraphQL type schema and live syntax and
# validation errors highlighted within the text.
#
# GraphQL queries typically start with a "{" character. Lines that start
# with a # are ignored.
#
# For example, to get a specific project and the title of issue #2:
#
# {
#   project(fullPath: "gitlab-org/graphql-sandbox") {
#     name
#     issue(iid: "2") {
#       title
#     }
#   }
# }
#
# Keyboard shortcuts:
#
#   Prettify query:  Shift-Ctrl-P (or press the prettify button)
#
#  Merge fragments:  Shift-Ctrl-M (or press the merge button)
#
#        Run Query:  Ctrl-Enter (or press the play button)
#
#    Auto Complete:  Ctrl-Space (or just start typing)
#
`;

const GraphiQLLogo = React.createElement(
  GraphiQL.Logo,
  {},
  React.createElement('a', {
    href: `${DOCS_URL_IN_EE_DIR}/api/graphql`,
    target: '_blank',
    title: 'GraphQL API documentation',
    dangerouslySetInnerHTML: { __html: gitlabLogo },
  }),
);

const graphiqlContainer = document.getElementById('graphiql-container');

function apolloFetcher(graphQLParams, { headers }) {
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

  const apolloObject = {
    query,
    variables: graphQLParams.variables,
    operationName: graphQLParams.operationName,
  };

  if (headers?.REQUEST_PATH) {
    apolloObject.context = {
      uri: headers?.REQUEST_PATH,
    };
  }

  return apolloClient.subscribe(apolloObject);
}

createRoot(graphiqlContainer).render(
  React.createElement(GraphiQL, { defaultQuery, fetcher: apolloFetcher }, GraphiQLLogo),
);

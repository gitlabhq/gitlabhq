/* eslint-disable no-console */

import '~/webpack';
import gitlabLogo from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?raw';
import { gql } from '@apollo/client';
import { GraphiQL } from 'graphiql';
import { getIntrospectionQuery, buildClientSchema } from 'graphql';
/* eslint-disable no-restricted-imports */
import React from 'react';
import { createRoot } from 'react-dom/client';
import { Mousetrap } from '~/lib/mousetrap';
import { DOCS_URL } from '~/constants';
/* eslint-enable no-restricted-imports */
import createDefaultClient, { fetchPolicies } from '~/lib/graphql';
import { keysFor, TOGGLE_PERFORMANCE_BAR } from '~/behaviors/shortcuts/keybindings';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

const apolloClient = createDefaultClient(
  {},
  {
    fetchPolicy: fetchPolicies.NO_CACHE,
    cacheConfig: { addTypename: false, typePolicies: {}, possibleTypes: {} },
  },
);

let introspectionResult = null;

const isProduction = process.env.NODE_ENV === 'production';
const graphiqlContainer = document.getElementById('graphiql-container');

const loadSchema = async () => {
  if (isProduction) {
    try {
      // Fetch static schema file in production
      const { introspectionSchemaPath } = graphiqlContainer.dataset;
      const response = await fetch(introspectionSchemaPath);
      if (!response.ok) {
        throw new Error(__('Cached schema not available'));
      }
      introspectionResult = await response.json();
      const schema = buildClientSchema(introspectionResult.data);
      console.log(__('Using cached GraphQL schema'));
      return schema;
    } catch (error) {
      console.log(__('Using live GraphQL introspection'));
      return null;
    }
  } else {
    console.log(__('Using live GraphQL introspection'));
    return null;
  }
};

const defaultQuery = `# Welcome to GraphQL explorer (GraphiQL)
#
# Full documentation: ${DOCS_URL}/api/graphql
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
    href: `${DOCS_URL}/api/graphql`,
    target: '_blank',
    title: 'GraphQL API documentation',
    dangerouslySetInnerHTML: { __html: gitlabLogo },
  }),
);

function apolloFetcher(graphQLParams, { headers }) {
  const isIntrospectionQuery =
    graphQLParams.query.includes('__schema') ||
    graphQLParams.query.includes('__type') ||
    graphQLParams.query === getIntrospectionQuery();

  if (introspectionResult && isIntrospectionQuery) {
    console.log(__('Using cached introspection result'));
    return Promise.resolve(introspectionResult);
  }

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

const initializeGraphiQL = async () => {
  try {
    const loadedSchema = await loadSchema();

    const graphiqlProps = {
      defaultQuery,
      fetcher: apolloFetcher,
      inputValueDeprecation: true,
    };

    if (loadedSchema) {
      graphiqlProps.schema = loadedSchema;
    }

    createRoot(graphiqlContainer).render(
      React.createElement(GraphiQL, graphiqlProps, GraphiQLLogo),
    );
  } catch (error) {
    console.error('Failed to initialize GraphiQL:', error);
    Sentry.captureException(error);
  }
};

initializeGraphiQL();

Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), Shortcuts.onTogglePerfBar);

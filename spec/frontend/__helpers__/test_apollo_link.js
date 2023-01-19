import { InMemoryCache, ApolloClient, ApolloLink, gql } from '@apollo/client/core';

const FOO_QUERY = gql`
  query {
    foo
  }
`;

/**
 * This function returns a promise that resolves to the final operation after
 * running an ApolloClient query with the given ApolloLink
 *
 * @typedef {Object} TestApolloLinkOptions
 * @property {Object} context the default context object sent along the ApolloLink chain
 *
 * @param {ApolloLink} subjectLink the ApolloLink which is under test
 * @param {TestApolloLinkOptions} options contains options to send a long with the query
 *
 * @returns Promise resolving to the resulting operation after running the subjectLink
 */
export const testApolloLink = (subjectLink, options = {}, query = FOO_QUERY) =>
  new Promise((resolve) => {
    const { context = {} } = options;

    // Use the terminating link to capture the final operation and resolve with this.
    const terminatingLink = new ApolloLink((operation) => {
      resolve(operation);

      return null;
    });

    const client = new ApolloClient({
      link: ApolloLink.from([subjectLink, terminatingLink]),
      // cache is a required option
      cache: new InMemoryCache(),
    });

    // Trigger a query so the ApolloLink chain will be executed.
    client.query({
      context,
      query,
    });
  });

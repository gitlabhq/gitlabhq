import { graphqlQuery } from '../graphql';

export default (server) => {
  server.post('/api/graphql', (schema, request) => {
    const batches = JSON.parse(request.requestBody);

    return Promise.all(
      batches.map(({ query, variables }) => graphqlQuery(query, variables, schema)),
    );
  });
};

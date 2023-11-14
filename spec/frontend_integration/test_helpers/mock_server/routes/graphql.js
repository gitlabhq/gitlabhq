import { graphqlQuery } from '../graphql';

export default (server) => {
  server.post('/api/graphql', (schema, request) => {
    const { query, variables } = JSON.parse(request.requestBody);

    return graphqlQuery(query, variables, schema);
  });
};

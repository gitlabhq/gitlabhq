import createDefaultClient from '~/lib/graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

export const defaultClient = createDefaultClient(resolvers, { typeDefs });

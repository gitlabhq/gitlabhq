import { setupServer } from 'msw/node';
import { handlers } from './handlers';

// Setup requests interception in Node
export const server = setupServer(...handlers);

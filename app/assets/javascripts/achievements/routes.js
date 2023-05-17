import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from './constants';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
  },
  {
    name: NEW_ROUTE_NAME,
    path: '/new',
  },
  {
    name: EDIT_ROUTE_NAME,
    path: '/:id/edit',
  },
];

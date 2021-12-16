import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from './constants';
import CrmContactsRoot from './components/contacts_root.vue';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
    component: CrmContactsRoot,
  },
  {
    name: NEW_ROUTE_NAME,
    path: '/new',
    component: CrmContactsRoot,
  },
  {
    name: EDIT_ROUTE_NAME,
    path: '/:id/edit',
    component: CrmContactsRoot,
  },
];

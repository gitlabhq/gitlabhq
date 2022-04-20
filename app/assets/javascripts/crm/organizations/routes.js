import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '../constants';
import OrganizationFormWrapper from './components/organization_form_wrapper.vue';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
  },
  {
    name: NEW_ROUTE_NAME,
    path: '/new',
    component: OrganizationFormWrapper,
  },
  {
    name: EDIT_ROUTE_NAME,
    path: '/:id/edit',
    component: OrganizationFormWrapper,
    props: { isEditMode: true },
  },
];

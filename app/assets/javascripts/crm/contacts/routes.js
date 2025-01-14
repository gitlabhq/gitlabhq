import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '../constants';
import ContactFormWrapper from './components/contact_form_wrapper.vue';
import CrmContactsRoot from './components/contacts_root.vue';

export default [
  {
    name: INDEX_ROUTE_NAME,
    path: '/',
    component: CrmContactsRoot,
    children: [
      {
        name: NEW_ROUTE_NAME,
        path: '/new',
        component: ContactFormWrapper,
      },
      {
        name: EDIT_ROUTE_NAME,
        path: '/:id/edit',
        component: ContactFormWrapper,
        props: { isEditMode: true },
      },
    ],
  },
];

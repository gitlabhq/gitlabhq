import CiResourceDetailsPage from '../components/pages/ci_resource_details_page.vue';
import { CI_RESOURCES_PAGE_NAME, CI_RESOURCE_DETAILS_PAGE_NAME } from './constants';

export const createRoutes = (listComponent) => {
  return [
    { name: CI_RESOURCES_PAGE_NAME, path: '', component: listComponent },
    { name: CI_RESOURCE_DETAILS_PAGE_NAME, path: '/:id+', component: CiResourceDetailsPage },
  ];
};

import CiResourceDetailsPage from '../components/pages/ci_resource_details_page.vue';
import TwoSourceBrowse from '../components/cells/two_source_browse.vue';
import {
  CI_RESOURCES_PAGE_NAME,
  CI_RESOURCES_CELLS_PAGE_NAME,
  CI_RESOURCE_DETAILS_PAGE_NAME,
} from './constants';

export const createRoutes = (listComponent) => {
  return [
    { name: CI_RESOURCES_PAGE_NAME, path: '', component: listComponent },
    { name: CI_RESOURCES_CELLS_PAGE_NAME, path: '/cells', component: TwoSourceBrowse },
    { name: CI_RESOURCE_DETAILS_PAGE_NAME, path: '/:id+', component: CiResourceDetailsPage },
  ];
};

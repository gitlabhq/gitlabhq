import { mountIssuablesListApp } from '~/issues_list';
import { initFilteredSearchServiceDesk } from '~/issues/init_filtered_search_service_desk';

initFilteredSearchServiceDesk();

if (gon.features?.vueIssuablesList) {
  mountIssuablesListApp();
}

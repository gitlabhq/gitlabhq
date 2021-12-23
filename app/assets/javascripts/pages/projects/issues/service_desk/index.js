import { initFilteredSearchServiceDesk } from '~/issues';
import { mountIssuablesListApp } from '~/issues_list';

initFilteredSearchServiceDesk();

if (gon.features?.vueIssuablesList) {
  mountIssuablesListApp();
}

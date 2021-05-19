import { mountIssuablesListApp } from '~/issues_list';
import FilteredSearchServiceDesk from './filtered_search';

const supportBotData = JSON.parse(
  document.querySelector('.js-service-desk-issues').dataset.supportBot,
);

if (document.querySelector('.filtered-search')) {
  const filteredSearchManager = new FilteredSearchServiceDesk(supportBotData);
  filteredSearchManager.setup();
}

if (gon.features?.vueIssuablesList) {
  mountIssuablesListApp();
}

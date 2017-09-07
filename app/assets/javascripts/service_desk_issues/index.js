import FilteredSearchServiceDesk from './filtered_search';

document.addEventListener('DOMContentLoaded', () => {
  const supportBotData = JSON.parse(
    document.querySelector('.js-service-desk-issues').dataset.supportBot,
  );

  this.filteredSearchManager = new FilteredSearchServiceDesk(supportBotData);

  this.filteredSearchManager.setup();
});

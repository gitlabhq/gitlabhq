import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportSourceListTable from '~/vue_shared/components/import/import_source_list_table.vue';
import ImportHistoryTableRow from '~/vue_shared/components/import/import_history_table_row.vue';
import ImportHistoryTableRowDestination from '~/vue_shared/components/import/import_history_table_row_destination.vue';
import ImportHistoryTableSource from '~/vue_shared/components/import/import_history_table_source.vue';
import ImportHistoryTableRowStats from '~/vue_shared/components/import/import_history_table_row_stats.vue';
import ImportHistoryStatusBadge from '~/vue_shared/components/import/import_history_status_badge.vue';
import ImportHistoryTableRowErrors from '~/vue_shared/components/import/import_history_table_row_errors.vue';

import { apiItems } from './source_list_mock_data';

import { countItemsAndNested } from './utils';

describe('ImportHistoryTableRowStats component', () => {
  let wrapper;

  const findAllDestinations = () => wrapper.findAllComponents(ImportHistoryTableRowDestination);
  const findAllErrors = () => wrapper.findAllComponents(ImportHistoryTableRowErrors);
  const findAllSources = () => wrapper.findAllComponents(ImportHistoryTableSource);
  const findAllStats = () => wrapper.findAllComponents(ImportHistoryTableRowStats);
  const findallStatusBadges = () => wrapper.findAllComponents(ImportHistoryStatusBadge);
  const findAllTableRows = () => wrapper.findAllComponents(ImportHistoryTableRow);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ImportSourceListTable, {
      propsData: {
        items: apiItems,
        ...props,
      },
    });
  };

  const topLevelItems = apiItems.length;
  const nestedItems = apiItems.filter((i) => i.nestedRow).length;
  const totalDataRows = topLevelItems + nestedItems;

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders a row for each item and each nested item', () => {
      expect(findAllTableRows()).toHaveLength(totalDataRows);
    });
    it('renders correct number of sources', () => {
      expect(findAllSources()).toHaveLength(totalDataRows);
    });
    it('renders destination for rows that have destination_slug defined', () => {
      const itemsWithDestinations = countItemsAndNested(apiItems, (i) => i.destination_slug);
      expect(findAllDestinations()).toHaveLength(itemsWithDestinations);
    });
    it('renders status icon for each row that has status_name defined', () => {
      const itemsWithStatus = countItemsAndNested(apiItems, (i) => i.status_name);
      expect(findallStatusBadges()).toHaveLength(itemsWithStatus);
    });
    it('renders stats for all items that have at least 1 stat', () => {
      const itemsWithStats = countItemsAndNested(
        apiItems,
        (i) => i.stats && Object.keys(i.stats).length,
      );
      expect(findAllStats()).toHaveLength(itemsWithStats);
    });
    it('renders errors for all items that have at least 1 error but no stats', () => {
      const itemsWithErrors = countItemsAndNested(
        apiItems,
        (i) => i.has_failures && !(i.stats && Object.keys(i.stats).length),
      );
      expect(findAllErrors()).toHaveLength(itemsWithErrors);
    });
  });
});

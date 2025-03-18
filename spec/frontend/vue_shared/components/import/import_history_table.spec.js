import { GlAvatarLabeled } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportHistoryTable from '~/vue_shared/components/import/import_history_table.vue';
import ImportHistoryTableRow from '~/vue_shared/components/import/import_history_table_row.vue';
import ImportHistoryTableRowDestination from '~/vue_shared/components/import/import_history_table_row_destination.vue';
import ImportHistoryTableSource from '~/vue_shared/components/import/import_history_table_source.vue';
import ImportHistoryTableRowStats from '~/vue_shared/components/import/import_history_table_row_stats.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ImportHistoryStatusBadge from '~/vue_shared/components/import/import_history_status_badge.vue';
import ImportHistoryTableRowErrors from '~/vue_shared/components/import/import_history_table_row_errors.vue';

import { apiItems } from './history_mock_data';

import { countItemsAndNested } from './utils';

describe('ImportHistoryTableRowStats component', () => {
  let wrapper;

  const findAllDestinations = () => wrapper.findAllComponents(ImportHistoryTableRowDestination);
  const findAllErrors = () => wrapper.findAllComponents(ImportHistoryTableRowErrors);
  const findAllGlAvatarLabeled = () => wrapper.findAllComponents(GlAvatarLabeled);
  const findAllNestedRows = () => wrapper.findAllByTestId('import-history-table-row-nested');
  const findAllSources = () => wrapper.findAllComponents(ImportHistoryTableSource);
  const findAllStats = () => wrapper.findAllComponents(ImportHistoryTableRowStats);
  const findallStatusBadges = () => wrapper.findAllComponents(ImportHistoryStatusBadge);
  const findAllTableRows = () => wrapper.findAllComponents(ImportHistoryTableRow);
  const findAllTimeago = () => wrapper.findAllComponents(TimeAgoTooltip);
  const findAllTopLevelRows = () => wrapper.findAllByTestId('import-history-table-row');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ImportHistoryTable, {
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
      expect(findAllTableRows().length).toBe(totalDataRows);

      expect(findAllTopLevelRows().length).toBe(apiItems.length);

      const itemsWithNestedRows = countItemsAndNested(apiItems, (i) => i.nestedRow);
      expect(findAllNestedRows().length).toBe(itemsWithNestedRows);
    });
    it('renders correct number of sources', () => {
      expect(findAllSources().length).toBe(totalDataRows);
    });
    it('renders correct number of destinations', () => {
      expect(findAllDestinations().length).toBe(totalDataRows);
    });
    it('renders a GlAvatarLabeled for each item where userAvatarProps is defined', () => {
      const itemsWithAvatarProps = countItemsAndNested(apiItems, (i) => i.userAvatarProps);
      expect(findAllGlAvatarLabeled().length).toBe(itemsWithAvatarProps);
    });
    it('renders a TimeAgoTooltip for each row', () => {
      expect(findAllTimeago().length).toBe(totalDataRows);
    });
    it('renders status icon for each row that has status_name defined', () => {
      const itemsWithStatus = countItemsAndNested(apiItems, (i) => i.status_name);
      expect(findallStatusBadges().length).toBe(itemsWithStatus);
    });
    it('renders stats for all items that have at least 1 stat', () => {
      const itemsWithStats = countItemsAndNested(
        apiItems,
        (i) => i.stats && Object.keys(i.stats).length,
      );
      expect(findAllStats().length).toBe(itemsWithStats);
    });
    it('renders errors for all items that have at least 1 error but no stats', () => {
      const itemsWithErrors = countItemsAndNested(
        apiItems,
        (i) => i.has_failures && !(i.stats && Object.keys(i.stats).length),
      );
      expect(findAllErrors().length).toBe(itemsWithErrors);
    });
  });
});

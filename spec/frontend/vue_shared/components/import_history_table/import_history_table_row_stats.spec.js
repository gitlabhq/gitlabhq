import { GlDrawer, GlIcon } from '@gitlab/ui';

import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportHistoryTableRowStats from '~/vue_shared/components/import/import_history_table_row_stats.vue';
import { apiItems } from './mock_data';

describe('ImportHistoryTableRowStats component', () => {
  let wrapper;

  const findStats = () => wrapper.findAllByTestId('import-history-table-row-stat');
  const findIcons = () => wrapper.findAllComponents(GlIcon);
  const findStatNames = () => wrapper.findAllByTestId('import-history-table-row-stat-name');
  const findStatCounts = () => wrapper.findAllByTestId('import-history-table-row-stat-count');
  const findErrorsToggleButton = () =>
    wrapper.findByTestId('import-history-table-row-stats-show-errors-button');
  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ImportHistoryTableRowStats, {
      propsData: {
        item: apiItems[0],
        ...props,
      },
    });
  };

  describe('renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders status icon for each stat', () => {
      expect(findStats().length).toEqual(findIcons().length);
    });
    it('renders name of stat', () => {
      expect(findStats().length).toEqual(findStatNames().length);
    });
    it('renders count of stats remaining', () => {
      expect(findStats().length).toEqual(findStatCounts().length);
    });
  });
  describe('errors', () => {
    beforeEach(() => {
      createComponent({ item: apiItems[1] });
    });

    it('renders toggle button and drawer of errors if hasFailures is true', () => {
      expect(findErrorsToggleButton().exists()).toBe(true);
      expect(findDrawer().exists()).toBe(true);
    });

    it('toggles drawer on button click', async () => {
      const button = findErrorsToggleButton();

      expect(findDrawer().props('open')).toBe(false);

      button.vm.$emit('click');
      await nextTick();

      expect(findDrawer().props('open')).toBe(true);
    });
  });
});

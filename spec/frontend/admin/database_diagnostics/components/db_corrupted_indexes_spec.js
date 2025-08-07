import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DbCorruptedIndexes from '~/admin/database_diagnostics/components/db_corrupted_indexes.vue';
import { collationMismatchResults } from '../mock_data';

describe('DbCorruptedIndexes component', () => {
  let wrapper;
  const defaultProps = {
    corruptedIndexes: collationMismatchResults.databases.main.corrupted_indexes,
  };

  const findIcon = () => wrapper.findByTestId('corrupted-indexes-icon');
  const findCountBadge = () => wrapper.findByTestId('corrupted-indexes-count');
  const findTable = () => wrapper.findByTestId('corrupted-indexes-table');
  const findNoCorruptedIndexesAlert = () => wrapper.findByTestId('no-corrupted-indexes-alert');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DbCorruptedIndexes, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when corrupted indexes exist', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays an error icon and count badge', () => {
      expect(findIcon().attributes()).toMatchObject({
        name: 'error',
        variant: 'danger',
      });

      expect(findCountBadge().text()).toBe(defaultProps.corruptedIndexes.length.toString());
    });

    it('displays a table with the corrupted indexes', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('does not show the "no corrupted indexes" message', () => {
      expect(findNoCorruptedIndexesAlert().exists()).toBe(false);
    });
  });

  describe('when no corrupted indexes exist', () => {
    beforeEach(() => {
      createComponent({ props: { corruptedIndexes: [] } });
    });

    it('displays a success icon without a count badge', () => {
      expect(findIcon().attributes()).toMatchObject({
        name: 'check-circle-filled',
        variant: 'success',
      });

      expect(findCountBadge().exists()).toBe(false);
    });

    it('shows a success alert instead of the table', () => {
      expect(findTable().exists()).toBe(false);
      expect(findNoCorruptedIndexesAlert().text()).toBe('No corrupted indexes detected.');
    });
  });
});

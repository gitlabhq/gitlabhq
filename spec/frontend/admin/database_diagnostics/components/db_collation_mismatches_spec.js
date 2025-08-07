import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DbCollationMismatches from '~/admin/database_diagnostics/components/db_collation_mismatches.vue';
import { collationMismatchResults } from '../mock_data';

describe('DbCollationMismatches component', () => {
  let wrapper;
  const defaultProps = {
    collationMismatches: collationMismatchResults.databases.main.collation_mismatches,
  };

  const findIcon = () => wrapper.findByTestId('collation-mismatches-icon');
  const findInfoAlert = () => wrapper.findByTestId('collation-info-alert');
  const findTable = () => wrapper.findByTestId('collation-mismatches-table');
  const findNoMismatchesAlert = () => wrapper.findByTestId('no-collation-mismatches-alert');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DbCollationMismatches, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  describe('when collation mismatches exist', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays an info icon', () => {
      expect(findIcon().attributes()).toMatchObject({
        name: 'information-o',
        variant: 'info',
      });
    });

    it('displays an informational alert about mismatches', () => {
      expect(findInfoAlert().text()).toBe(
        'Collation mismatches are informational and might not indicate a problem.',
      );
    });

    it('displays a table with the mismatches', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('does not show the "no mismatches" message', () => {
      expect(findNoMismatchesAlert().exists()).toBe(false);
    });
  });

  describe('when no collation mismatches exist', () => {
    beforeEach(() => {
      createComponent({ props: { collationMismatches: [] } });
    });

    it('displays a success icon', () => {
      expect(findIcon().attributes()).toMatchObject({
        name: 'check-circle-filled',
        variant: 'success',
      });
    });

    it('shows a success alert instead of the mismatches table', () => {
      expect(findInfoAlert().exists()).toBe(false);
      expect(findTable().exists()).toBe(false);
      expect(findNoMismatchesAlert().text()).toBe('No collation mismatches detected.');
    });
  });
});

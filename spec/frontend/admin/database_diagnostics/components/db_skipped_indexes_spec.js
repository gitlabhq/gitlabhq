import { GlAlert, GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DbSkippedIndexes from '~/admin/database_diagnostics/components/db_skipped_indexes.vue';
import { collationMismatchResults } from '../mock_data';

describe('DbSkippedIndexes component', () => {
  let wrapper;
  const defaultProps = {
    skippedIndexes: collationMismatchResults.databases.main.skipped_indexes,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(DbSkippedIndexes, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findTable = () => wrapper.findComponent(GlTableLite);
  const findSkippedCountBadge = () => wrapper.findComponent(GlBadge);
  const findSection = () => wrapper.findByTestId('skipped-indexes-section');

  describe('when indexes are skipped', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays an information icon', () => {
      expect(findIcon().attributes()).toMatchObject({
        name: 'information-o',
        variant: 'info',
      });
    });

    it('displays the count of skipped indexes', () => {
      expect(findSkippedCountBadge().text()).toBe(defaultProps.skippedIndexes.length.toString());
    });

    it('displays an informational alert', () => {
      expect(findAlert().text()).toBe(
        'Large table corruption checks skipped. Manual checking recommended.',
      );
    });

    it('displays table with skipped indexes', () => {
      expect(findTable().exists()).toBe(true);
    });
  });

  describe('when no indexes are skipped', () => {
    beforeEach(() => {
      createComponent({ props: { skippedIndexes: [] } });
    });

    it('does not render the section', () => {
      expect(findSection().exists()).toBe(false);
    });
  });
});
